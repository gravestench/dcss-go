package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// A sparse overlay uses the production layered VFS and startup checks.
func wizlabModGame(t *testing.T, directory string) *Game {
	t.Helper()

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88303,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

// Failed staging must preserve the gate, actor state, and RNG so a later
// valid choice can still enter on the same turn.
func wizlabFailedStageUnchanged(t *testing.T, g *Game,
	layoutID, want string) {
	t.Helper()

	placeWizlabPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.wizlab.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_wizlab_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   layoutID,
		},
		"expected_branch_id": "BRANCH_WIZLAB",
		"expected_level_id":  int64(3301),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), want) {
		t.Fatalf("Wizard Lab mod failure %q was accepted: %v", want, err)
	}

	afterState := g.Snapshot()
	afterState.EntityCursor = beforeState.EntityCursor
	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Wizard Lab destination changed the saved session")
	}
}

// Adding one new DES path makes it selectable by its own positive weight.
func TestWizlabSparseModAddsMap(t *testing.T) {
	g := wizlabModGame(t, "testdata/wizlab-addon-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_wizlab_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "my_wizlab_foyer",
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
		"my_wizlab_foyer" {
		t.Fatalf("sparse Wizard Lab map selected %q", got)
	}
}

// Replacing one same-path source file changes its actual placed cells.
func TestWizlabSamePathModReplacesMap(t *testing.T) {
	g := wizlabModGame(t, "testdata/wizlab-replace-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_wizlab_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "wizlab_alistair",
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
			case terrain.ExitWizlab:
				exits++
			}
		}
	}

	if floors != 8 || exits != 1 {
		t.Fatalf("replacement geometry has %d floors and %d exits",
			floors, exits)
	}
}

// A zero-weight effective map leaves an attempted gate intact.
func TestWizlabZeroWeightModPreservesGate(t *testing.T) {
	g := wizlabModGame(t, "testdata/wizlab-zero-mod")
	wizlabFailedStageUnchanged(t, g,
		"wizlab_alistair", "not eligible")
}

// A missing Lua hook fails startup with its requested name.
func TestWizlabBrokenHookFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/wizlab-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(88304,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if g != nil {
		_ = g.Close()
	}

	if err == nil || !strings.Contains(err.Error(), "missing_hook") {
		t.Fatalf("broken Wizard Lab hook was accepted: %v", err)
	}
}

// Duplicate event clocks must fail in the staged transaction. Restore
// validation is too late because the outside gate would already be used.
func TestWizlabDuplicateClockPreservesGate(t *testing.T) {
	g := wizlabModGame(t, "testdata/wizlab-duplicate-clock-mod")
	wizlabFailedStageUnchanged(t, g,
		"wizlab_borgnjor", "multiple Borgnjor source clocks")
}
