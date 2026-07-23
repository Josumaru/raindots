package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type plan struct {
	resume  bool
	symlink bool
	build   bool
	font    bool
	deps    bool
}

func defaultPlan(f *facts) *plan {
	return &plan{
		resume:  f.prevRun != nil,
		symlink: true,
		build:   true,
		font:    true,
		deps:    f.needsDeps(),
	}
}

type evStep struct {
	idx   int
	title string
}

type evLine struct {
	line      string
	transient bool
}

type evDone struct {
	err error
	idx int
}

type estep struct {
	id    string
	title string
	fn    func(*engine) error
}

type engine struct {
	f   *facts
	p   *plan
	dry bool

	events    chan any
	logf      *os.File
	logPath   string
	logMu     sync.Mutex
	backupDir string

	state   *runState
	pending []string

	steps []estep
}

func newEngine(f *facts, p *plan, dry bool) *engine {
	e := &engine{f: f, p: p, dry: dry}
	e.openLog()

	if p.resume && f.prevRun != nil {
		e.state = f.prevRun
		if f.prevRun.BackupDir != "" {
			if fi, err := os.Stat(f.prevRun.BackupDir); err == nil && fi.IsDir() {
				e.backupDir = f.prevRun.BackupDir
			}
		}
	}

	e.steps = []estep{
		{"backup", "Backing up existing configs", stepBackup},
		{"deps", "Checking system dependencies", stepDeps},
		{"symlink", "Symlinking configs", stepSymlink},
		{"build", "Building rain CLI", stepBuild},
		{"font", "Installing Google Sans Flex font", stepFont},
		{"verify", "Verifying installation", stepVerify},
	}
	return e
}

func (e *engine) openLog() {
	dir := os.TempDir()
	if !e.dry {
		dir = filepath.Join(e.f.homeDir, ".local", "state", "rain")
		if err := os.MkdirAll(dir, 0o755); err != nil {
			dir = os.TempDir()
		}
	}
	e.logPath = filepath.Join(dir, "install.log")
	e.logf, _ = os.OpenFile(e.logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644)
	e.log(fmt.Sprintf("---- rain installer run %s (dry=%v) ----", time.Now().Format(time.RFC3339), e.dry))
}

func (e *engine) log(s string) {
	e.logMu.Lock()
	defer e.logMu.Unlock()
	if e.logf != nil {
		fmt.Fprintln(e.logf, s)
	}
}

func (e *engine) say(s string) {
	e.log(s)
	if e.events != nil {
		e.events <- evLine{line: s}
	}
}

func (e *engine) sayf(format string, a ...any) { e.say(fmt.Sprintf(format, a...)) }

func (e *engine) sayTransient(s string) {
	if e.events != nil {
		e.events <- evLine{line: s, transient: true}
	}
}

func (e *engine) runFrom(idx int) chan any {
	e.events = make(chan any, 256)
	go func() {
		for i := idx; i < len(e.steps); i++ {
			s := e.steps[i]
			e.events <- evStep{idx: i, title: s.title}
			e.log("==== step " + s.id + " ====")
			if e.p.resume && e.state != nil && e.state.has(s.id) {
				e.say("finished in the previous run, resuming past it")
				continue
			}
			if err := s.fn(e); err != nil {
				e.sayf("step %s failed: %v", s.id, err)
				e.events <- evDone{err: err, idx: i}
				return
			}
			e.markStepDone(s.id)
		}
		e.clearState()
		e.events <- evDone{idx: len(e.steps)}
	}()
	return e.events
}

func (e *engine) markStepDone(id string) {
	if e.dry {
		return
	}
	if e.state == nil {
		e.state = &runState{Started: time.Now()}
	}
	e.state.Completed = append(e.state.Completed, id)
	saveState(e.f.homeDir, e.state)
}

func (e *engine) clearState() {
	if !e.dry {
		clearState(e.f.homeDir)
	}
}

func (e *engine) cmd(dir string, name string, args ...string) error {
	line := name + " " + strings.Join(args, " ")
	if e.dry {
		e.say("DRYRUN: " + line)
		return nil
	}
	e.say("$ " + line)
	c := exec.Command(name, args...)
	c.Dir = dir
	pr, pw := io.Pipe()
	c.Stdout, c.Stderr = pw, pw
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		rd := bufio.NewReader(pr)
		var buf []byte
		var lastProgress time.Time
		for {
			b, err := rd.ReadByte()
			if err != nil {
				if ln := cleanTermLine(string(buf)); ln != "" {
					e.say("  " + ln)
				}
				return
			}
			switch b {
			case '\n':
				if ln := cleanTermLine(string(buf)); ln != "" {
					e.say("  " + ln)
				}
				buf = buf[:0]
			case '\r':
				if nxt, perr := rd.Peek(1); perr == nil && nxt[0] == '\n' {
					continue
				}
				if ln := cleanTermLine(string(buf)); ln != "" && time.Since(lastProgress) > 80*time.Millisecond {
					lastProgress = time.Now()
					e.sayTransient("  " + ln)
				}
				buf = buf[:0]
			default:
				buf = append(buf, b)
			}
		}
	}()
	err := c.Run()
	pw.Close()
	wg.Wait()
	if err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}

func cleanTermLine(s string) string {
	s = strings.TrimRight(s, "\r\n")
	if i := strings.LastIndexByte(s, '\r'); i >= 0 {
		s = s[i+1:]
	}
	var b strings.Builder
	for _, r := range s {
		switch {
		case r == '\t':
			b.WriteString("  ")
		case r < 0x20 || r == 0x7f:
		default:
			b.WriteRune(r)
		}
	}
	return b.String()
}

func copyTree(src, dst string) error {
	info, err := os.Lstat(src)
	if err != nil {
		return err
	}
	switch {
	case info.Mode()&os.ModeSymlink != 0:
		tgt, err := os.Readlink(src)
		if err != nil {
			return err
		}
		return os.Symlink(tgt, dst)
	case info.IsDir():
		if err := os.MkdirAll(dst, info.Mode().Perm()); err != nil {
			return err
		}
		ents, err := os.ReadDir(src)
		if err != nil {
			return err
		}
		for _, ent := range ents {
			if err := copyTree(filepath.Join(src, ent.Name()), filepath.Join(dst, ent.Name())); err != nil {
				return err
			}
		}
		return nil
	default:
		in, err := os.Open(src)
		if err != nil {
			return err
		}
		defer in.Close()
		out, err := os.OpenFile(dst, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, info.Mode().Perm())
		if err != nil {
			return err
		}
		defer out.Close()
		_, err = io.Copy(out, in)
		return err
	}
}

// ---- steps ----

var backupMove = []string{
	".config/hypr",
	".config/quickshell",
}

func stepBackup(e *engine) error {
	root := filepath.Join(e.f.homeDir, ".local", "state", "rain")
	if e.dry {
		e.say("DRYRUN: back up existing configs")
		return nil
	}

	if e.backupDir == "" {
		e.backupDir = filepath.Join(root, "backup-"+time.Now().Format("20060102-150405"))
	}
	if err := os.MkdirAll(e.backupDir, 0o755); err != nil {
		return err
	}

	for _, rel := range backupMove {
		src := filepath.Join(e.f.homeDir, rel)
		dst := filepath.Join(e.backupDir, rel)
		if _, err := os.Lstat(src); err != nil {
			continue
		}
		if _, err := os.Lstat(dst); err == nil {
			e.say("already backed up " + rel)
			continue
		}
		if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
			return err
		}
		if err := os.Rename(src, dst); err != nil {
			if err := copyTree(src, dst); err != nil {
				return err
			}
			os.RemoveAll(src)
		}
		e.say("moved aside " + rel)
	}
	e.say("backup at " + e.backupDir)
	return nil
}

func stepDeps(e *engine) error {
	if !e.p.deps {
		e.say("dependency check skipped by choice")
		return nil
	}

	var missing []string
	if !e.f.hasGit {
		missing = append(missing, "git")
	}
	if !e.f.hasGo {
		missing = append(missing, "go")
	}
	if !e.f.hasHyprland {
		missing = append(missing, "hyprland")
	}
	if !e.f.hasQuickshell {
		missing = append(missing, "quickshell")
	}

	if len(missing) == 0 {
		e.say("all dependencies found")
		return nil
	}

	e.say("missing: " + strings.Join(missing, ", "))
	e.say("install them with your package manager and re-run, or toggle deps off")
	if e.dry {
		return nil
	}
	return fmt.Errorf("missing dependencies: %s", strings.Join(missing, " "))
}

func stepSymlink(e *engine) error {
	if !e.p.symlink {
		e.say("symlink step skipped by choice")
		return nil
	}

	repo := e.f.repoRoot()
	if repo == "" {
		return fmt.Errorf("cannot find raindots repo root")
	}
	configDir := filepath.Join(repo, "rain", "config")
	target := filepath.Join(e.f.homeDir, ".config")

	e.say("repo root: " + repo)

	for _, dir := range []string{"hypr", "quickshell"} {
		src := filepath.Join(configDir, dir)
		link := filepath.Join(target, dir)

		if _, err := os.Stat(src); err != nil {
			e.sayf("  [SKIP] %s (source not found)", dir)
			continue
		}

		if existing, err := os.Lstat(link); err == nil {
			if existing.Mode()&os.ModeSymlink != 0 {
				if old, _ := os.Readlink(link); old == src {
					e.sayf("  [OK] %s already linked", dir)
					continue
				}
			}
			bak := link + ".bak." + fmt.Sprintf("%d", time.Now().Unix())
			if err := os.Rename(link, bak); err != nil {
				return fmt.Errorf("backup %s: %w", dir, err)
			}
			e.sayf("  backed up existing %s -> %s", dir, bak)
		}

		if err := os.Symlink(src, link); err != nil {
			return fmt.Errorf("symlink %s: %w", dir, err)
		}
		e.sayf("  linked %s -> %s", link, src)
	}

	// Seed browser flags
	seeds := []struct {
		name, content string
	}{
		{"chrome-flags.conf", "--password-store=gnome-libsecret\n--ozone-platform-hint=wayland\n--gtk-version=4\n--ignore-gpu-blocklist\n--enable-features=TouchpadOverscrollHistoryNavigation\n--enable-wayland-ime\n--disable-features=ExtensionManifestV2Unsupported\n"},
		{"chromium-flags.conf", "--ozone-platform-hint=wayland\n--gtk-version=4\n"},
		{"code-flags.conf", "--ozone-platform-hint=wayland\n--gtk-version=4\n"},
		{"electron-flags.conf", "--ozone-platform-hint=wayland\n--gtk-version=4\n"},
	}
	for _, s := range seeds {
		p := filepath.Join(target, s.name)
		if _, err := os.Lstat(p); err == nil {
			continue
		}
		if e.dry {
			e.sayf("  seed %s (%d bytes)", s.name, len(s.content))
			continue
		}
		if err := os.WriteFile(p, []byte(s.content), 0o644); err != nil {
			e.sayf("  [WARN] could not write %s: %v", s.name, err)
			continue
		}
		e.sayf("  seeded %s", s.name)
	}

	return nil
}

func stepBuild(e *engine) error {
	if !e.p.build {
		e.say("build step skipped by choice")
		return nil
	}

	if !e.f.hasGo {
		e.say("go not found, skipping rain CLI build")
		e.say("install go and re-run, or toggle download pre-built binary")
		if e.dry {
			return nil
		}
		return fmt.Errorf("go not found, cannot build rain CLI")
	}

	repo := e.f.repoRoot()
	if repo == "" {
		return fmt.Errorf("cannot find raindots repo root")
	}

	cliDir := filepath.Join(repo, "rain", "cli")
	binDir := filepath.Join(repo, "rain", "bin")

	if e.dry {
		e.say("DRYRUN: go build -o " + binDir + "/rain " + cliDir)
		return nil
	}

	if err := os.MkdirAll(binDir, 0o755); err != nil {
		return err
	}

	e.say("building rain CLI...")
	if err := e.cmd(cliDir, "go", "build", "-o", filepath.Join(binDir, "rain"), "."); err != nil {
		return err
	}
	e.say("built " + filepath.Join(binDir, "rain"))

	// Also symlink rain/bin -> ~/.config/rain
	binTarget := filepath.Join(e.f.homeDir, ".config", "rain")
	if existing, err := os.Lstat(binTarget); err == nil {
		if existing.Mode()&os.ModeSymlink == 0 {
			bak := binTarget + ".bak." + fmt.Sprintf("%d", time.Now().Unix())
			os.Rename(binTarget, bak)
			e.say("backed up " + binTarget + " -> " + bak)
		} else {
			os.Remove(binTarget)
		}
	}
	if err := os.Symlink(binDir, binTarget); err != nil {
		return fmt.Errorf("symlink rain/bin: %w", err)
	}
	e.say("linked " + binTarget + " -> " + binDir)

	return nil
}

func stepFont(e *engine) error {
	if !e.p.font {
		e.say("font step skipped by choice")
		return nil
	}

	if e.dry {
		e.say("DRYRUN: check and install Google Sans Flex font")
		return nil
	}

	// Check if font is already installed
	if b, err := exec.Command("fc-list", ":lang=en").Output(); err == nil {
		if strings.Contains(strings.ToLower(string(b)), "google sans flex") {
			e.say("Google Sans Flex already installed")
			return nil
		}
	}

	repo := e.f.repoRoot()
	if repo == "" {
		e.say("cannot find repo root, skipping font install")
		return nil
	}

	cacheDir := filepath.Join(repo, "cache")
	srcDir := filepath.Join(cacheDir, "google-sans-flex")
	targetDir := filepath.Join(e.f.homeDir, ".local", "share", "fonts", "rain-google-sans-flex")

	// Check if we have a local copy
	if _, err := os.Stat(srcDir); err != nil {
		e.say("Google Sans Flex not in cache, skipping (download manually)")
		e.say("see: https://github.com/end-4/google-sans-flex")
		return nil
	}

	if err := os.MkdirAll(targetDir, 0o755); err != nil {
		return err
	}

	entries, err := os.ReadDir(srcDir)
	if err != nil {
		return err
	}
	for _, ent := range entries {
		src := filepath.Join(srcDir, ent.Name())
		dst := filepath.Join(targetDir, ent.Name())
		if ent.IsDir() {
			if err := copyTree(src, dst); err != nil {
				return err
			}
		} else {
			in, err := os.Open(src)
			if err != nil {
				continue
			}
			out, err := os.OpenFile(dst, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o644)
			if err != nil {
				in.Close()
				continue
			}
			io.Copy(out, in)
			in.Close()
			out.Close()
		}
	}
	e.say("installed Google Sans Flex -> " + targetDir)

	// Update font cache
	exec.Command("fc-cache", "-fv").Run()
	e.say("updated font cache")

	return nil
}

func stepVerify(e *engine) error {
	if e.dry {
		e.say("DRYRUN: verify symlinks and binaries")
		return nil
	}

	var bad []string
	check := func(ok bool, what string) {
		if ok {
			e.say(gCheck + " " + what)
		} else {
			bad = append(bad, what)
			e.say(gBad + " " + what)
		}
	}

	cfg := filepath.Join(e.f.homeDir, ".config")

	// Check symlinks
	for _, dir := range []string{"hypr", "quickshell"} {
		link := filepath.Join(cfg, dir)
		if target, err := os.Readlink(link); err == nil {
			check(true, "~/.config/"+dir+" -> "+target)
		} else {
			check(false, "~/.config/"+dir+" symlink exists")
		}
	}

	// Check rain binary
	bin := filepath.Join(cfg, "rain", "rain")
	if _, err := os.Stat(bin); err == nil {
		check(true, "rain CLI at ~/.config/rain/rain")
	} else {
		check(false, "rain CLI binary exists")
	}

	// Check rain CLI works
	if b, err := exec.Command(bin, "status").Output(); err == nil {
		check(true, "rain CLI responds: "+strings.TrimSpace(string(b)))
	} else {
		check(false, "rain CLI is functional")
	}

	if len(bad) > 0 {
		return fmt.Errorf("%d check(s) failed: %s", len(bad), strings.Join(bad, "; "))
	}
	e.say("all checks passed")
	return nil
}
