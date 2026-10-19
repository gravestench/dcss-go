package terminal

import (
	"testing"

	"crawl/internal/game"
)

func testPresentationPolicy(t *testing.T) presentationPolicy {
	t.Helper()
	g, err := game.NewScenario(7, "WPN_RAPIER", "Presenter")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g.PresentationPolicy
}
