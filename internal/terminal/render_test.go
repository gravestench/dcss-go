package terminal

import (
	"strings"
	"testing"
)

func TestRenderShowsStartingMP(t *testing.T) {
	m := newModel(t)
	content := m.View().Content
	for _, want := range []string{"HP:18/18", "MP:1/1"} {
		if !strings.Contains(content, want) {
			t.Fatalf("render missing %q: %s", want, content)
		}
	}
}
