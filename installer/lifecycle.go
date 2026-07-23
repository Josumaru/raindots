package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

type runState struct {
	Started   time.Time `json:"started"`
	Completed []string  `json:"completed"`
	BackupDir string    `json:"backupDir,omitempty"`
}

func (s *runState) has(id string) bool {
	for _, c := range s.Completed {
		if c == id {
			return true
		}
	}
	return false
}

func stateDir(homeDir string) string {
	return filepath.Join(homeDir, ".local", "state", "rain")
}

func statePath(homeDir string) string {
	return filepath.Join(stateDir(homeDir), "install-state.json")
}

func loadState(homeDir string) *runState {
	b, err := os.ReadFile(statePath(homeDir))
	if err != nil {
		return nil
	}
	var s runState
	if json.Unmarshal(b, &s) == nil {
		return &s
	}
	return nil
}

func saveState(homeDir string, s *runState) error {
	dir := stateDir(homeDir)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}
	tmp := filepath.Join(dir, fmt.Sprintf(".install-state-%d.tmp", time.Now().UnixNano()))
	if err := os.WriteFile(tmp, b, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, statePath(homeDir))
}

func clearState(homeDir string) {
	os.Remove(statePath(homeDir))
}
