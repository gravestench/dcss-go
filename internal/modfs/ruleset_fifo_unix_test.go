//go:build darwin || linux

package modfs

import (
	"path/filepath"
	"strings"
	"syscall"
	"testing"
)

func TestOverlayRejectsNamedPipeWithoutOpeningIt(t *testing.T) {
	overlay := t.TempDir()
	pipe := filepath.Join(overlay, "blocked.lua")

	if err := syscall.Mkfifo(pipe, 0o600); err != nil {
		t.Skipf("named pipes unavailable: %v", err)
	}

	_, err := Load(overlay)

	if err == nil {
		t.Fatal("named pipe was accepted as Lua source")
	}

	if !strings.Contains(err.Error(), "nonregular file") {
		t.Fatalf("unclear special-file error: %v", err)
	}
}
