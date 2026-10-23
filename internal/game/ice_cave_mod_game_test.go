package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// Load one sparse user layer through the same VFS path that ordinary play
// uses. A fixture may add or replace only the DES file relevant to its case.
func iceCaveModGame(t *testing.T, directory string) *Game {
	t.Helper()

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88165, "SP_HUMAN",
		"JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g
}

// The generic staged transaction must leave the saved session unchanged
// when a requested mod child is ineligible or cannot fit its source grid.
func iceCaveFailedStageUnchanged(t *testing.T, g *Game, layoutID string,
	want string) {
	t.Helper()

	placeIceCavePortalForTest(t, g, false)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.ice_cave.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_ice_cave_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   layoutID,
			"hard":        false,
		},
		"expected_branch_id": "BRANCH_ICE_CAVE",
		"expected_level_id":  int64(3101),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), want) {
		t.Fatalf("Ice Cave mod failure %q was accepted: %v", want, err)
	}

	afterState := g.Snapshot()

	// A failed stage may reserve an entity ID but cannot change durable state.
	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Ice Cave child changed the saved session")
	}
}

// A single added DES file enters the effective pool and can be requested
// without editing the bundled catalog or its source children.
func TestIceCaveSparseModAddsChild(t *testing.T) {
	g := iceCaveModGame(t, "testdata/ice-cave-addon-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_ice_cave_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "my_ice_gallery",
			"hard":        false,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer func() {
		if err := stage.rollback(); err != nil {
			t.Error(err)
		}
	}()

	if got := g.levels[stage.levelID].VaultID(); got != "my_ice_gallery" {
		t.Fatalf("sparse Ice Cave map selected %q", got)
	}
}

// Replacing one bundled path changes only that effective source map.
func TestIceCaveSamePathModReplacesChild(t *testing.T) {
	g := iceCaveModGame(t, "testdata/ice-cave-replace-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_ice_cave_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "ice_cave_small_giant",
			"hard":        true,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer func() {
		if err := stage.rollback(); err != nil {
			t.Error(err)
		}
	}()

	if got := g.levels[stage.levelID].VaultID(); got != "ice_cave_small_giant" {
		t.Fatalf("replaced Ice Cave map selected %q", got)
	}

	// The replacement is a five-cell square with eight plain interior
	// cells and one exit. The bundled giant map has a much larger cavern.
	floors := 0
	exits := 0

	for _, row := range g.levels[stage.levelID].Cells() {
		for _, cell := range row {
			switch cell {
			case terrain.Floor:
				floors++

			case terrain.ExitIceCave:
				exits++
			}
		}
	}

	if floors != 8 || exits != 1 {
		t.Fatalf("replacement geometry has %d floors and %d exits",
			floors, exits)
	}
}

// Effective zero weight excludes even an explicitly requested source ID.
func TestIceCaveZeroWeightModPreservesGate(t *testing.T) {
	g := iceCaveModGame(t, "testdata/ice-cave-zero-mod")
	iceCaveFailedStageUnchanged(t, g, "ice_cave_small_giant",
		"not eligible")
}

// A valid DES with impossible geometry fails inside staging and rolls back.
func TestIceCaveTooWideModPreservesGate(t *testing.T) {
	g := iceCaveModGame(t, "testdata/ice-cave-too-wide-mod")
	iceCaveFailedStageUnchanged(t, g, "ice_cave_small_giant",
		"does not fit")
}

// An invalid hook fails during catalog boot, before a session can draw a
// gate or mutate a player. Mod authors receive the offending path.
func TestIceCaveBrokenHookFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/ice-cave-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88166, "SP_HUMAN",
		"JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if g != nil {
		g.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "missing_hook") {
		t.Fatalf("broken Ice Cave hook did not fail at boot: %v", err)
	}
}
