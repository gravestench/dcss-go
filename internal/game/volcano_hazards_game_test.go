package game

import (
	"encoding/json"
	"testing"

	"crawl/internal/terrain"
)

// Build the requested source floor through placement and population, then
// retain the transaction until the event test has inspected its live grid.
func stageVolcanoHazardMap(t *testing.T, id string) (*Game, int) {
	t.Helper()

	g := newGeneratedTestGame(t, 88166)
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   id,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		if err := stage.rollback(); err != nil {
			t.Error(err)
		}
	})

	return g, stage.levelID
}

// Decode a homogeneous Akara list without depending on its Go bridge's
// internal []any representation.
func volcanoIntList(t *testing.T, value any) []int64 {
	t.Helper()

	data, err := json.Marshal(value)

	if err != nil {
		t.Fatal(err)
	}

	var result []int64

	if err := json.Unmarshal(data, &result); err != nil {
		t.Fatal(err)
	}

	return result
}

// All nine source phases run in order. A player-occupied source cell never
// turns into lava, while each successfully converted group hardens in
// reverse order during phases 7–9.
func TestVolcanoOverflowNinePhases(t *testing.T) {
	g, levelID := stageVolcanoHazardMap(t, "volcano_overflow")
	store := g.scripts.Components()["world.volcano_overflow"]

	if len(store.Entities()) != 1 {
		t.Fatalf("overflow clocks = %d", len(store.Entities()))
	}

	entity := store.Entities()[0]
	state, _ := store.Get(entity)
	xValue, _ := state.Get("positions_x")
	yValue, _ := state.Get("positions_y")
	groupValue, _ := state.Get("groups")
	xs := volcanoIntList(t, xValue)
	ys := volcanoIntList(t, yValue)
	groups := volcanoIntList(t, groupValue)
	protected := -1

	for index, group := range groups {
		if group == 2 {
			protected = index
			break
		}
	}

	if protected < 0 {
		t.Fatal("source overflow has no phase-two cells")
	}

	if _, err := g.scripts.Policy("save.validate_volcano_hazards",
		map[string]any{
			"levels": g.vaultValidationLevels(),
		}); err != nil {
		t.Fatalf("initial overflow state is invalid: %v", err)
	}

	protectedX := int(xs[protected])
	protectedY := int(ys[protected])
	initial := g.levels[levelID].terrain[protectedY][protectedX]
	entryX := -1
	entryY := -1

	for y, row := range g.levels[levelID].Cells() {
		for x, feature := range row {
			if feature == terrain.ExitVolcano {
				entryX = x
				entryY = y
				break
			}
		}

		if entryX >= 0 {
			break
		}
	}

	if entryX < 0 {
		t.Fatal("overflow map has no safe arrival exit")
	}

	for phase := int64(1); phase <= 9; phase++ {
		state, _ = store.Get(entity)

		if err := state.Set("countdown_aut", int64(1)); err != nil {
			t.Fatal(err)
		}

		playerX := entryX
		playerY := entryY

		if phase == 2 {
			playerX = protectedX
			playerY = protectedY
		}

		if err := g.runWorldPolicy("world.volcano_hazards",
			map[string]any{
				"player": map[string]any{
					"level_id": int64(levelID),
					"x":        int64(playerX),
					"y":        int64(playerY),
				},
				"elapsed_aut": int64(10),
			}); err != nil {
			t.Fatal(err)
		}

		state, _ = store.Get(entity)
		value, _ := state.Get("phase")

		if value != phase {
			t.Fatalf("overflow phase = %v, want %d", value, phase)
		}

		if _, err := g.scripts.Policy("save.validate_volcano_hazards",
			map[string]any{
				"levels": g.vaultValidationLevels(),
			}); err != nil {
			t.Fatalf("overflow phase %d did not validate: %v",
				phase, err)
		}

		if phase == 2 &&
			g.levels[levelID].terrain[protectedY][protectedX] != initial {
			t.Fatal("player cell turned into lava")
		}

		if phase == 9 {
			for index, group := range groups {
				cell := g.levels[levelID].terrain[ys[index]][xs[index]]

				wasConverted := index != protected && group != 2

				if wasConverted && cell == terrain.Lava {
					t.Fatal("an earlier lava group did not harden")
				}
			}
		}
	}

	if err := state.Set("phase", int64(10)); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Policy("save.validate_volcano_hazards",
		map[string]any{
			"levels": g.vaultValidationLevels(),
		}); err == nil {
		t.Fatal("forged Volcano overflow phase was accepted")
	}
}

// An occupied cave doorway remains available on its first firing. The
// next unoccupied firing consumes exactly one marker and changes its grid.
func TestVolcanoCaveCollapseRespectsPlayer(t *testing.T) {
	g, levelID := stageVolcanoHazardMap(t, "volcano_caves")
	store := g.scripts.Components()["world.volcano_collapse"]

	if len(store.Entities()) != 1 {
		t.Fatalf("cave clocks = %d", len(store.Entities()))
	}

	entity := store.Entities()[0]
	state, _ := store.Get(entity)
	indexValue, _ := state.Get("record_indices")
	initial := volcanoIntList(t, indexValue)

	if len(initial) < 2 {
		t.Fatal("source cave has too few doorway markers")
	}

	// With every source position potentially selected, repeat short
	// firings until the deterministic stream selects an occupied one.
	for attempts := 0; attempts < 20; attempts++ {
		state, _ = store.Get(entity)
		xValue, _ := state.Get("positions_x")
		yValue, _ := state.Get("positions_y")
		xs := volcanoIntList(t, xValue)
		ys := volcanoIntList(t, yValue)

		if len(xs) == 0 {
			break
		}

		if err := state.Set("countdown_aut", int64(1)); err != nil {
			t.Fatal(err)
		}

		if err := g.runWorldPolicy("world.volcano_hazards",
			map[string]any{
				"player": map[string]any{
					"level_id": int64(levelID),
					"x":        xs[0],
					"y":        ys[0],
				},
				"elapsed_aut": int64(10),
			}); err != nil {
			t.Fatal(err)
		}

		state, _ = store.Get(entity)
		remainingValue, _ := state.Get("record_indices")
		remaining := volcanoIntList(t, remainingValue)

		if len(remaining) == len(xs) {
			if g.levels[levelID].terrain[ys[0]][xs[0]] ==
				terrain.StoneWall {
				t.Fatal("occupied doorway collapsed")
			}

			return
		}
	}

	t.Fatal("deterministic collapse sequence never chose the occupied doorway")
}

// A remaining doorway must still be passable. A forged saved wall cannot
// silently consume a source marker without updating the event component.
func TestVolcanoRejectsWallAtRemainingDoorway(t *testing.T) {
	g, levelID := stageVolcanoHazardMap(t, "volcano_caves")
	store := g.scripts.Components()["world.volcano_collapse"]
	state, _ := store.Get(store.Entities()[0])
	xValue, _ := state.Get("positions_x")
	yValue, _ := state.Get("positions_y")
	x := int(volcanoIntList(t, xValue)[0])
	y := int(volcanoIntList(t, yValue)[0])

	if err := g.levels[levelID].SetCell(x, y, terrain.StoneWall); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Policy("save.validate_volcano_hazards",
		map[string]any{
			"levels": g.vaultValidationLevels(),
		}); err == nil {
		t.Fatal("remaining cave doorway became a wall without rejection")
	}
}

// Source collapse recolours the new rock as well as replacing terrain.
// The tint belongs to the same saved grid as other vault wall colours.
func TestVolcanoCollapseWallKeepsSourceColour(t *testing.T) {
	g, levelID := stageVolcanoHazardMap(t, "volcano_caves")
	store := g.scripts.Components()["world.volcano_collapse"]
	state, _ := store.Get(store.Entities()[0])
	xValue, _ := state.Get("positions_x")
	yValue, _ := state.Get("positions_y")
	xs := volcanoIntList(t, xValue)
	ys := volcanoIntList(t, yValue)
	playerX := -1
	playerY := -1

	for y, row := range g.levels[levelID].Cells() {
		for x, cell := range row {
			if cell == terrain.ExitVolcano {
				playerX = x
				playerY = y
				break
			}
		}

		if playerX >= 0 {
			break
		}
	}

	if playerX < 0 {
		t.Fatal("cave has no safe return arch")
	}

	if err := state.Set("countdown_aut", int64(1)); err != nil {
		t.Fatal(err)
	}

	if err := g.runWorldPolicy("world.volcano_hazards", map[string]any{
		"player": map[string]any{
			"level_id": int64(levelID),
			"x":        int64(playerX),
			"y":        int64(playerY),
		},
		"elapsed_aut": int64(10),
	}); err != nil {
		t.Fatal(err)
	}

	for index, x := range xs {
		y := ys[index]

		if g.levels[levelID].terrain[y][x] != terrain.StoneWall {
			continue
		}

		colour, _ := g.levels[levelID].CellColour(int(x), int(y))

		if colour != "lightred" {
			t.Fatalf("collapsed wall colour = %q", colour)
		}

		return
	}

	t.Fatal("no cave doorway collapsed")
}
