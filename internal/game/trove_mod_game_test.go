package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// Load a sparse overlay through the same layered VFS used by a launched game.
func troveModGame(t *testing.T, directory string) *Game {
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

// Staging fails before the debit, so the outside gate, player, and saved
// RNG streams must be identical. The entity cursor is only an allocator.
func troveFailedStageUnchanged(t *testing.T, g *Game,
	layoutID, want string) {
	t.Helper()

	placeTrovePortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.trove.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_trove_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   layoutID,
		},
		"expected_branch_id": "BRANCH_TROVE",
		"expected_level_id":  int64(2701),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), want) {
		t.Fatalf("Trove mod failure %q was accepted: %v", want, err)
	}

	afterState := g.Snapshot()
	afterState.EntityCursor = beforeState.EntityCursor
	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Trove destination changed the saved session")
	}
}

// A new DES path joins the effective reward catalog without an index file.
func TestTroveSparseModAddsMap(t *testing.T) {
	g := troveModGame(t, "testdata/trove-addon-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_trove_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "my_trove_gallery",
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
		"my_trove_gallery" {
		t.Fatalf("sparse Trove map selected %q", got)
	}
}

// Same-path overlay replacement changes the actual staged geometry.
func TestTroveSamePathModReplacesMap(t *testing.T) {
	g := troveModGame(t, "testdata/trove-replace-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_trove_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "trove_simple",
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

			case terrain.ExitTrove:
				exits++
			}
		}
	}

	if floors != 8 || exits != 1 {
		t.Fatalf("replacement geometry has %d floors and %d exits",
			floors, exits)
	}
}

// An effective zero weight cannot be bypassed with an explicit map ID.
func TestTroveZeroWeightModPreservesGate(t *testing.T) {
	g := troveModGame(t, "testdata/trove-zero-mod")
	troveFailedStageUnchanged(t, g, "trove_simple", "not eligible")
}

// Impossible geometry fails before the paid gate can be consumed.
func TestTroveTooWideModPreservesGate(t *testing.T) {
	g := troveModGame(t, "testdata/trove-wide-mod")
	troveFailedStageUnchanged(t, g, "trove_simple", "does not fit")
}

// Hook names are validated at startup, before any world state is generated.
func TestTroveBrokenHookFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/trove-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88166,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if g != nil {
		_ = g.Close()
	}

	if err == nil {
		t.Fatal("broken Trove hook was accepted")
	}

	if !strings.Contains(err.Error(), "missing_trove_hook") {
		t.Fatalf("broken Trove hook did not fail at boot: %v", err)
	}
}
