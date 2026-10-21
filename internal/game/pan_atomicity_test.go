package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// A mod policy can fail after the portal moves the player but before the
// previous Pan region is retired. The entire travel action must roll back.
func TestPanRetirementFailureRestoresPreviousState(t *testing.T) {
	rules, err := modfs.Load("testdata/pan-retirement-failure-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		7403,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000
	placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	health.Max = originalMax
	health.Current = originalMax
	placePortalForTest(t, g, terrain.ExitPandemonium)
	before := g.Snapshot()
	_, err = g.Step(Command{Kind: CommandUpstairs})

	if err == nil {
		t.Fatal("expected retirement failure")
	}

	if !strings.Contains(err.Error(), "forced retirement failure") {
		t.Fatalf("unexpected retirement error: %v", err)
	}

	beforeJSON, _ := json.Marshal(before)
	afterJSON, _ := json.Marshal(g.Snapshot())

	if !bytes.Equal(beforeJSON, afterJSON) {
		t.Fatal("failed travel changed the saved game state")
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatalf("game unusable after rollback: %v", err)
	}
}

// Every generated Pan floor must be saveable immediately after arrival,
// including source maps that draw stair glyphs in their authored geometry.
func TestPanGeneratedRegionRestoresWithAuthoredStairs(t *testing.T) {
	g := newGeneratedTestGame(t, 7417)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000
	placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	health.Max = originalMax
	health.Current = originalMax

	level := g.levels[g.panState.ActiveLevelID]

	if level.VaultID() != "rand_demon_7" {
		t.Fatalf("expected stair-bearing source map, got %s", level.VaultID())
	}

	transitCount := 0

	for _, row := range level.Cells() {
		for _, feature := range row {
			if feature == terrain.StairsUp {
				t.Fatal("Pan retained an unlinked upward stair")
			}

			if feature == terrain.TransitPandemonium {
				transitCount++
			}
		}
	}

	if transitCount == 0 {
		t.Fatal("source upward stair did not become a Pan transit portal")
	}

	restored, err := RestoreWithRules(g.Snapshot(), g.rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
}
