package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// Load a sparse overlay through the same mod stack as the executable.
// The destination builder should not need an ID list in Go.
func gauntletModGame(t *testing.T, directory string) *Game {
	t.Helper()

	rules, err := modfs.Load(directory)

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(99144,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

// A bad overlay must fail before the staged transaction spends the gate,
// moves the player, or changes the saved RNG stream. The entity cursor
// may advance during rolled-back staging and is not gameplay state.
func gauntletFailedStageUnchanged(t *testing.T,
	directory, expected string) {
	t.Helper()

	g := gauntletModGame(t, directory)
	placeGauntletPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.gauntlet.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_gauntlet_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "gammafunk_gauntlet_shortcut",
		},
		"expected_branch_id": "BRANCH_GAUNTLET",
		"expected_level_id":  int64(3601),
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), expected) {
		t.Fatalf("malformed Gauntlet overlay %q was accepted: %v",
			directory, err)
	}

	afterState := g.Snapshot()

	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("failed Gauntlet staging changed the saved session")
	}
}

// Malformed source topologies are rejected before an outside
// entrance can be consumed by the new floor's generation attempt.
func TestGauntletMalformedModsRollBack(t *testing.T) {
	cases := []struct {
		name      string
		directory string
		errorText string
	}{
		{
			name:      "missing exit",
			directory: "testdata/gauntlet-no-exit-mod",
			errorText: "no live entry-side return arch",
		},

		{
			name:      "missing boss exit",
			directory: "testdata/gauntlet-boss-no-exit-mod",
			errorText: "no live boss-room return arch",
		},

		{
			name:      "missing transporter source",
			directory: "testdata/gauntlet-missing-link-mod",
			errorText: "unused transporter destination",
		},

		{
			name:      "duplicate transporter landing",
			directory: "testdata/gauntlet-duplicate-link-mod",
			errorText: "duplicate transporter destination",
		},
	}

	for _, item := range cases {
		t.Run(item.name, func(t *testing.T) {
			gauntletFailedStageUnchanged(t,
				item.directory, item.errorText)
		})
	}
}

// Adding one parent file lets the existing weighted catalog and staged
// builder place it, including its unchanged nested arenas and exit.
func TestGauntletSparseModAddsParent(t *testing.T) {
	g := gauntletModGame(t, "testdata/gauntlet-addon-mod")
	stage, err := g.stageGeneratedLevel(
		"world.generate_gauntlet_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "my_gauntlet_shortcut",
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

	floor := g.levels[stage.levelID]

	if floor.VaultID() != "my_gauntlet_shortcut" ||
		len(floor.VaultIDs()) < 3 {
		t.Fatal("sparse parent did not compose nested Gauntlet maps")
	}
}

// Replacing an existing path changes only its authored corner terrain.
// A one-cell difference proves the effective overlay was placed, while
// all other source choices and links remained on the same seeded stream.
func TestGauntletSamePathModReplacesParent(t *testing.T) {
	baseline := newGeneratedTestGame(t, 99144)
	replacement := gauntletModGame(t,
		"testdata/gauntlet-replace-mod")
	input := map[string]any{
		"species_id":  "SP_HUMAN",
		"player_name": "Tester",
		"layout_id":   "gammafunk_gauntlet_shortcut",
	}

	first, err := baseline.stageGeneratedLevel(
		"world.generate_gauntlet_level", input)

	if err != nil {
		t.Fatal(err)
	}

	defer func() {
		if err := first.rollback(); err != nil {
			t.Error(err)
		}
	}()

	second, err := replacement.stageGeneratedLevel(
		"world.generate_gauntlet_level", input)

	if err != nil {
		t.Fatal(err)
	}

	defer func() {
		if err := second.rollback(); err != nil {
			t.Error(err)
		}
	}()

	left := baseline.levels[first.levelID].Cells()
	right := replacement.levels[second.levelID].Cells()
	changed := 0

	for y, row := range left {
		for x, feature := range row {
			if feature != right[y][x] {
				changed++
			}
		}
	}

	if changed != 1 {
		t.Fatalf("sparse parent replacement changed %d cells, want one", changed)
	}
}
