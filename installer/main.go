package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const minTermW, minTermH = 72, 20

type frameMsg time.Time
type scanMsg struct{ f *facts }

type planItem struct {
	label  string
	detail string
	on     *bool
	locked bool
}

type model struct {
	w, h  int
	frame int
	state string

	f       *facts
	p       *plan
	items   []planItem
	sel     int
	confirm bool

	eng           *engine
	events        chan any
	stepIdx       int
	logTail       []string
	tailTransient bool
	failIdx       int
	failMsg       string
	intAsk        bool

	dry bool
}

func newTUIModel(dry bool) model {
	return model{state: "scan", dry: dry}
}

func (m model) tickCmd() tea.Cmd {
	d := 250 * time.Millisecond
	if m.state == "scan" || m.state == "install" {
		d = 90 * time.Millisecond
	}
	return tea.Tick(d, func(t time.Time) tea.Msg { return frameMsg(t) })
}

func scanCmd() tea.Msg { return scanMsg{f: detect()} }

func (m model) Init() tea.Cmd {
	return tea.Batch(m.tickCmd(), func() tea.Msg { return scanCmd() })
}

func (m model) waitEv() tea.Cmd {
	ch := m.events
	return func() tea.Msg { return <-ch }
}

func buildItems(f *facts, p *plan) []planItem {
	var it []planItem
	if f.prevRun != nil {
		it = append(it, planItem{
			"Resume the previous run",
			fmt.Sprintf("%d step(s) already finished; keeps that run's backup dir and skips them", len(f.prevRun.Completed)),
			&p.resume, false,
		})
	}
	if f.needsDeps() {
		var missing []string
		if !f.hasGit {
			missing = append(missing, "git")
		}
		if !f.hasGo {
			missing = append(missing, "go")
		}
		if !f.hasHyprland {
			missing = append(missing, "hyprland")
		}
		if !f.hasQuickshell {
			missing = append(missing, "quickshell")
		}
		it = append(it, planItem{
			"Install system dependencies",
			"missing: " + strings.Join(missing, ", ") + " — install with your package manager",
			&p.deps, false,
		})
	}
	d := "symlinks rain/config/{hypr,quickshell} to ~/.config/{hypr,quickshell}"
	if f.symlinksOk {
		d += "; symlinks already point to the repo"
	}
	it = append(it, planItem{"Create config symlinks", d, &p.symlink, false})

	d = "builds the rain CLI from rain/cli/ using Go"
	if f.hasRainBin {
		d += "; existing binary at ~/.config/rain/rain"
	}
	it = append(it, planItem{"Build rain CLI", d, &p.build, false})

	it = append(it, planItem{"Google Sans Flex font", "installs the default UI font", &p.font, false})

	return it
}

func (m *model) startInstall() tea.Cmd {
	m.eng = newEngine(m.f, m.p, m.dry)
	m.events = m.eng.runFrom(0)
	m.stepIdx, m.logTail = 0, nil
	m.state = "install"
	return tea.Batch(m.tickCmd(), m.waitEv())
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.w, m.h = msg.Width, msg.Height
		return m, nil
	case frameMsg:
		m.frame++
		return m, m.tickCmd()
	case scanMsg:
		m.f = msg.f
		m.p = defaultPlan(m.f)
		m.items = buildItems(m.f, m.p)
		m.sel = firstToggle(m.items)
		m.state = "plan"
		return m, nil
	case evStep:
		m.stepIdx = msg.idx
		m.tailTransient = false
		return m, tea.Batch(m.waitEv(), tea.ClearScreen)
	case evLine:
		if msg.transient && m.tailTransient && len(m.logTail) > 0 {
			m.logTail[len(m.logTail)-1] = msg.line
		} else {
			m.logTail = append(m.logTail, msg.line)
			if len(m.logTail) > 400 {
				m.logTail = m.logTail[len(m.logTail)-400:]
			}
		}
		m.tailTransient = msg.transient
		return m, m.waitEv()
	case evDone:
		if msg.err != nil {
			m.failIdx, m.failMsg = msg.idx, msg.err.Error()
			m.state = "failed"
		} else {
			m.state = "done"
		}
		return m, nil
	case tea.KeyMsg:
		return m.onKey(msg.String())
	}
	return m, nil
}

func (m model) onKey(k string) (tea.Model, tea.Cmd) {
	if k == "ctrl+c" {
		if m.state == "install" && !m.intAsk {
			m.intAsk = true
			return m, nil
		}
		return m, tea.Quit
	}
	if m.state == "install" && m.intAsk {
		m.intAsk = false
	}
	switch m.state {
	case "plan":
		if m.confirm {
			switch k {
			case "y", "Y", "enter":
				m.confirm = false
				return m, m.startInstall()
			case "n", "N", "esc":
				m.confirm = false
			}
			return m, nil
		}
		switch k {
		case "q":
			return m, tea.Quit
		case "j", "down":
			for i := m.sel + 1; i < len(m.items); i++ {
				if m.items[i].on != nil {
					m.sel = i
					break
				}
			}
		case "k", "up":
			for i := m.sel - 1; i >= 0; i-- {
				if m.items[i].on != nil {
					m.sel = i
					break
				}
			}
		case " ", "space":
			if len(m.items) > 0 && m.items[m.sel].on != nil && !m.items[m.sel].locked {
				*m.items[m.sel].on = !*m.items[m.sel].on
			}
		case "enter":
			m.confirm = true
		}
	case "done":
		switch k {
		case "q", "enter":
			return m, tea.Quit
		}
	case "failed":
		switch k {
		case "r":
			m.events = m.eng.runFrom(m.failIdx)
			m.state = "install"
			return m, tea.Batch(m.tickCmd(), m.waitEv())
		case "q":
			return m, tea.Quit
		}
	}
	return m, nil
}

func firstToggle(items []planItem) int {
	for i, it := range items {
		if it.on != nil {
			return i
		}
	}
	return 0
}

// ---- views ----

func (m model) View() string {
	if m.w == 0 {
		return ""
	}
	if m.w < minTermW || m.h < minTermH {
		msg := lipgloss.JoinVertical(lipgloss.Center,
			bold(cYell, "↔  Please enlarge your terminal"), "",
			fg(cText, "Rain installer needs at least "+fmt.Sprintf("%d × %d.", minTermW, minTermH)),
			fg(cSub, "Current size: "+fmt.Sprintf("%d × %d.", m.w, m.h)))
		return lipgloss.Place(m.w, m.h, lipgloss.Center, lipgloss.Center, msg)
	}
	var body string
	switch m.state {
	case "scan":
		body = m.viewScan()
	case "plan":
		body = m.viewPlan()
	case "install":
		body = m.viewInstall()
	case "done":
		body = m.viewDone()
	case "failed":
		body = m.viewFailed()
	}
	frame := lipgloss.Place(m.w, m.h, lipgloss.Center, lipgloss.Center, body)
	foot := m.footer()
	if foot != "" {
		lines := strings.Split(frame, "\n")
		if len(lines) >= 2 {
			lines[len(lines)-2] = lipgloss.PlaceHorizontal(m.w, lipgloss.Center, foot)
		}
		frame = strings.Join(lines, "\n")
	}
	return frame
}

func (m model) footer() string {
	switch m.state {
	case "plan":
		if m.confirm {
			return keyHint("y", "install") + hintSep() + keyHint("n", "back")
		}
		return keyHint("↑↓", "move") + hintSep() + keyHint("space", "toggle") + hintSep() +
			keyHint("enter", "install") + hintSep() + keyHint("q", "quit")
	case "install":
		if m.intAsk {
			return bold(cRed, "press ctrl+c again to quit")
		}
		return fg(cDim, "installing, do not interrupt") + hintSep() + fg(cDim, "log: "+m.logPath())
	case "done":
		return keyHint("q", "quit")
	case "failed":
		return keyHint("r", "retry failed step") + hintSep() + keyHint("q", "quit")
	}
	return ""
}

func (m model) logPath() string {
	if m.eng != nil {
		return m.eng.logPath
	}
	return ""
}

func (m model) header(sub string) string {
	tag := fg(cSub, "rain installer")
	if m.dry {
		tag += fg(cYell, "  [dry run]")
	}
	return banner(m.frame/2) + "\n" + tag + "\n\n" + sub
}

func (m model) viewScan() string {
	sp := spinFrames[m.frame%len(spinFrames)]
	return m.header(fg(cBrand, sp) + " " + fg(cText, "inspecting this machine…"))
}

func (m model) viewPlan() string {
	f := m.f
	iw := clamp(m.w-14, 60, 90)

	var s strings.Builder
	row := func(k, v string) {
		s.WriteString(fg(cSub, padTo(k, 12)) + fg(cText, truncW(v, iw-14)) + "\n")
	}
	row("system", f.distroName)
	row("host", f.hostname)
	row("gpu", f.gpuSummary())
	if f.rainInstalled {
		row("rain", "already installed; repair mode")
	} else if f.symlinksOk {
		row("symlinks", "point to repo")
	}
	row("repo", truncW(f.repoRoot(), iw-14))
	info := sty().Border(border()).BorderForeground(cBlue).Padding(0, 2).Render(padLines(strings.TrimRight(s.String(), "\n"), iw))

	var t strings.Builder
	for i, it := range m.items {
		if it.on == nil {
			t.WriteString("  " + fg(cSub, "· "+it.label) + "\n")
			continue
		}
		cur := "  "
		if i == m.sel {
			cur = fg(cBrand, gSel)
		}
		state := fg(cGreen, gOn)
		if !*it.on {
			state = fg(cDim, gOff)
		}
		if it.locked {
			state = fg(cYell, gOff)
		}
		lbl := fg(cText, padTo(it.label, 28))
		if i == m.sel {
			lbl = bold(cText, padTo(it.label, 28))
		}
		t.WriteString(cur + state + "  " + lbl + "\n")
		if i == m.sel {
			t.WriteString("     " + fg(cSub, truncW(it.detail, iw-6)) + "\n")
		}
	}
	toggles := sty().Border(border()).BorderForeground(cDim).Padding(0, 2).Render(padLines(strings.TrimRight(t.String(), "\n"), iw))

	body := m.header(bold(cText, "Installation plan for "+f.hostname) + "\n\n" + info + "\n" + toggles)
	if m.confirm {
		q := bold(cBrand, "Install the Rain desktop with these choices?")
		body += "\n\n" + sty().Border(borderDouble()).BorderForeground(cBrand).Padding(0, 2).Render(q)
	}
	return body
}

func (m model) viewInstall() string {
	iw := clamp(m.w-12, 58, 90)
	bw := clamp(iw-10, 28, 60)
	logRows := clamp(m.h-18-len(m.eng.steps), 3, 10)

	total := len(m.eng.steps)
	prog := float64(m.stepIdx) / float64(total)
	fill := clamp(int(prog*float64(bw)), 0, bw)
	bar := fg(cBrand, strings.Repeat(gFull, fill)) + fg(cDim, strings.Repeat(gEmpty, bw-fill)) +
		fg(cSub, fmt.Sprintf(" %2d/%d", m.stepIdx, total))

	var b strings.Builder
	b.WriteString(bold(cBrand, "Installing the Rain desktop") + "\n\n")
	b.WriteString(bar + "\n\n")
	for i, s := range m.eng.steps {
		switch {
		case i < m.stepIdx:
			b.WriteString(fg(cGreen, gCheck+" ") + fg(cSub, s.title) + "\n")
		case i == m.stepIdx:
			b.WriteString(fg(cBrand, spinFrames[m.frame%len(spinFrames)]) + " " + fg(cText, s.title) + "\n")
		default:
			b.WriteString(fg(cDim, gPend+" "+s.title) + "\n")
		}
	}
	b.WriteString(fg(cDim, strings.Repeat(ruleCh(), iw)) + "\n")
	tail := m.logTail
	if len(tail) > logRows {
		tail = tail[len(tail)-logRows:]
	}
	for _, ln := range tail {
		b.WriteString(fg(cDim, truncW(ln, iw)) + "\n")
	}
	for i := len(tail); i < logRows; i++ {
		b.WriteString("\n")
	}
	return sty().Border(border()).BorderForeground(cBrand).Padding(1, 2).
		Render(padLines(strings.TrimRight(b.String(), "\n"), iw))
}

func (m model) viewDone() string {
	iw := clamp(m.w-14, 56, 90)
	var b strings.Builder
	b.WriteString(bold(cGreen, gCheck+" The Rain desktop is installed") + "\n\n")
	b.WriteString(fg(cText, "Log in to Hyprland to start using your new desktop.") + "\n\n")
	b.WriteString(fg(cSub, gBullet+" symlinks:     ") + fg(cText, "~/.config/{hypr,quickshell}") + "\n")
	b.WriteString(fg(cSub, gBullet+" CLI:          ") + fg(cText, "rain --help") + "\n")
	b.WriteString(fg(cSub, gBullet+" keybinds:     ") + fg(cText, "Super+/ (cheatsheet)") + "\n")
	if m.eng != nil && m.eng.backupDir != "" {
		b.WriteString(fg(cSub, gBullet+" backup:       ") + fg(cText, m.eng.backupDir) + "\n")
	}
	if m.eng != nil && m.eng.logPath != "" {
		b.WriteString(fg(cSub, gBullet+" log:          ") + fg(cText, m.eng.logPath) + "\n")
	}
	return sty().Border(borderDouble()).BorderForeground(cGreen).Padding(1, 2).
		Render(padLines(strings.TrimRight(b.String(), "\n"), iw))
}

func (m model) viewFailed() string {
	iw := clamp(m.w-14, 56, 90)
	var b strings.Builder
	step := "?"
	if m.eng != nil && m.failIdx < len(m.eng.steps) {
		step = m.eng.steps[m.failIdx].title
	}
	b.WriteString(bold(cRed, gBad+" Install failed") + "\n\n")
	b.WriteString(fg(cText, "Step: ") + fg(cYell, step) + "\n")
	b.WriteString(fg(cText, "Error: ") + fg(cRed, truncW(m.failMsg, iw-8)) + "\n\n")
	tail := m.logTail
	if len(tail) > 8 {
		tail = tail[len(tail)-8:]
	}
	for _, ln := range tail {
		b.WriteString(fg(cDim, truncW(ln, iw)) + "\n")
	}
	b.WriteString("\n" + fg(cSub, "Full log: ") + fg(cText, m.logPath()) + "\n")
	if m.eng != nil && m.eng.backupDir != "" {
		b.WriteString(fg(cSub, "Backup: ") + fg(cText, m.eng.backupDir) + "\n")
	}
	return sty().Border(border()).BorderForeground(cRed).Padding(1, 2).
		Render(padLines(strings.TrimRight(b.String(), "\n"), iw))
}

// ---- headless ----

func runHeadless(dry bool) int {
	fmt.Println(bold(cBrand, "installer") + fg(cSub, " (headless)"))
	f := detect()
	p := defaultPlan(f)

	fmt.Printf("system: %s | host: %s | gpu: %s\n", f.distroName, f.hostname, f.gpuSummary())
	if f.prevRun != nil {
		fmt.Printf("resuming interrupted run: %d step(s) already done\n", len(f.prevRun.Completed))
	}
	fmt.Printf("plan: symlink=%v build=%v font=%v deps=%v resume=%v\n",
		p.symlink, p.build, p.font, p.deps, p.resume)

	e := newEngine(f, p, dry)
	ev := e.runFrom(0)
	for msg := range ev {
		switch msg := msg.(type) {
		case evStep:
			fmt.Println(bold(cBrand, fmt.Sprintf("==> [%d/%d] %s", msg.idx+1, len(e.steps), msg.title)))
		case evLine:
			if msg.transient {
				continue
			}
			fmt.Println("    " + msg.line)
		case evDone:
			if msg.err != nil {
				fmt.Println(bold(cRed, "install failed: "+msg.err.Error()))
				fmt.Println("log: " + e.logPath)
				return 1
			}
			fmt.Println(bold(cGreen, "the Rain desktop is installed"))
			if e.backupDir != "" {
				fmt.Println("old configs: " + e.backupDir)
			}
			return 0
		}
	}
	return 1
}

// ---- entry ----

func die(msg string) {
	fmt.Fprintln(os.Stderr, "installer: "+msg)
	os.Exit(1)
}

func stdoutIsTTY() bool {
	fi, err := os.Stdout.Stat()
	return err == nil && fi.Mode()&os.ModeCharDevice != 0
}

func main() {
	yes := flag.Bool("yes", false, "run non-interactively with the default plan")
	dry := flag.Bool("dry-run", false, "print every command instead of running it")
	flag.Parse()

	initGlyphs()

	if os.Geteuid() == 0 {
		die("run as your normal user, not root")
	}

	if *yes {
		os.Exit(runHeadless(*dry))
	}
	if !stdoutIsTTY() {
		die("unable to run interactively; re-run with --yes for the default plan")
	}

	p := tea.NewProgram(newTUIModel(*dry), tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		die(err.Error())
	}
}
