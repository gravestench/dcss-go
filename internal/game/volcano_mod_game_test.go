package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// A sparse overlay uses the same layered VFS and boot validation as play.
func volcanoModGame(t *testing.T, directory string) *Game {
	t.Helper()

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88165,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

// A failed staged destination cannot spend the gate, move the player, or
// consume RNG. Entity allocation cursors are harmless and excluded here.
func volcanoFailedStageUnchanged(t *testing.T, g *Game,
	layoutID, want string) {
	t.Helper()

	placeVolcanoPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.volcano.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_volcano_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   layoutID,
		},
		"expected_branch_id": "BRANCH_VOLCANO",
		"expected_level_id":  int64(3201),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), want) {
		t.Fatalf("Volcano mod failure %q was accepted: %v", want, err)
	}

	afterState := g.Snapshot()

	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Volcano destination changed the saved session")
	}
}

// A new DES path becomes a positive-weight destination without an index.
func TestVolcanoSparseModAddsMap(t *testing.T) {
	g := volcanoModGame(t, "testdata/volcano-addon-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "my_volcano_foyer",
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

	if got := g.levels[stage.levelID].VaultID(); got !=
		"my_volcano_foyer" {
		t.Fatalf("sparse Volcano map selected %q", got)
	}
}

// Replacing one same-path source file changes its actual staged geometry.
func TestVolcanoSamePathModReplacesMap(t *testing.T) {
	g := volcanoModGame(t, "testdata/volcano-replace-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "volcano_pools",
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

	floors := 0
	exits := 0

	for _, row := range g.levels[stage.levelID].Cells() {
		for _, cell := range row {
			switch cell {
			case terrain.Floor:
				floors++

			case terrain.ExitVolcano:
				exits++
			}
		}
	}

	if floors != 8 || exits != 1 {
		t.Fatalf("replacement geometry has %d floors and %d exits",
			floors, exits)
	}
}

// An effective zero weight rejects explicit requests without gate changes.
func TestVolcanoZeroWeightModPreservesGate(t *testing.T) {
	g := volcanoModGame(t, "testdata/volcano-zero-mod")
	volcanoFailedStageUnchanged(t, g, "volcano_pools", "not eligible")
}

// A too-wide replacement fails during staging and rolls back all state.
func TestVolcanoTooWideModPreservesGate(t *testing.T) {
	g := volcanoModGame(t, "testdata/volcano-wide-mod")
	volcanoFailedStageUnchanged(t, g, "volcano_pools", "does not fit")
}

// A broken named hook fails at boot with its mod path, before any draw.
func TestVolcanoBrokenHookFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/volcano-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88166,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if g != nil {
		_ = g.Close()
	}

	if err == nil {
		t.Fatal("broken Volcano hook was accepted")
	}

	if !strings.Contains(err.Error(), "missing_hook") {
		t.Fatalf("broken Volcano hook did not fail at boot: %v", err)
	}
}
