package game

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
	"crawl/internal/terrain"
)

// Stage and populate every top-level Volcano map through the production
// transaction. Parsing Lua alone cannot catch rejected actors or items.
func TestVolcanoAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/volcano")

	if err != nil {
		t.Fatal(err)
	}

	count := 0
	directory := os.Getenv("CRAWL_VOLCANO_SNAPSHOT_DIR")
	var index strings.Builder

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		index.WriteString("Volcano source layouts, seed 88164\n")
		index.WriteString("Coordinates are zero-based, origin at top left.\n")
		index.WriteString("All return arches point to the exact outside test gate.\n\n")
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")

		if strings.HasPrefix(id, "vgs_") ||
			strings.HasPrefix(id, "vl_") ||
			strings.HasPrefix(id, "vts_") {
			continue
		}

		count++
		t.Run(id, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88164)
			var outside point

			if directory != "" {
				outside = placeVolcanoPortalForTest(t, g)
			}

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

			defer func() {
				if err := stage.rollback(); err != nil {
					t.Error(err)
				}
			}()

			floor := g.levels[stage.levelID]

			if floor == nil {
				t.Fatalf("Volcano %s has no staged floor", id)
			}

			if floor.BranchID != "BRANCH_VOLCANO" ||
				floor.VaultID() != id || len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Volcano %s lost source records", id)
			}

			var exits []point

			for y, row := range floor.Cells() {
				for x, cell := range row {
					if cell == terrain.ExitVolcano {
						exits = append(exits, point{
							x: x,
							y: y,
						})
					}
				}
			}

			if len(exits) == 0 {
				t.Fatalf("populated Volcano %s has no return exit", id)
			}

			if directory == "" {
				return
			}

			var record save.LevelRecord

			for _, candidate := range g.Snapshot().Levels {
				if candidate.ID == floor.ID {
					record = candidate
					break
				}
			}

			var connections strings.Builder

			for _, exit := range exits {
				fmt.Fprintf(&connections,
					"Volcano exit (%d,%d) -> Dungeon:1 (%d,%d), exact outside gate\n",
					exit.x, exit.y, outside.x, outside.y)
			}

			name := id + ".txt"
			body := formatLevelTextSnapshot(record, nil)
			body += connections.String()

			if err := os.WriteFile(filepath.Join(directory, name),
				[]byte(body), 0o644); err != nil {
				t.Fatal(err)
			}

			fmt.Fprintf(&index, "%s  %s\n", id, name)
			helperIDs := strings.Join(floor.VaultIDs()[1:], ", ")

			if helperIDs == "" {
				helperIDs = "none"
			}

			fmt.Fprintf(&index, "  helpers: %s\n", helperIDs)
			index.WriteString(connections.String())
		})
	}

	if count != 14 {
		t.Fatalf("expected 14 top-level Volcano layouts, got %d", count)
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}

// A chained V site creates one master with all authored positions. Four
// independent clocks would desynchronize a source eruption after restore.
func TestVolcanoChainedFogHasOneClock(t *testing.T) {
	g := newGeneratedTestGame(t, 88164)
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "volcano_bunker",
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

	masters := 0

	for _, entity := range g.Snapshot().Entities {
		for _, state := range entity.Dynamic {
			if state.Schema != "world.fog_machine" {
				continue
			}

			var chain string

			if err := json.Unmarshal(state.Values["chain"], &chain); err != nil {
				t.Fatal(err)
			}

			if chain != "V" {
				continue
			}

			masters++
			var indices []int64

			if err := json.Unmarshal(state.Values["record_indices"],
				&indices); err != nil {
				t.Fatal(err)
			}

			if len(indices) != 4 {
				t.Fatalf("chained V positions = %d, want 4", len(indices))
			}
		}
	}

	if masters != 1 {
		t.Fatalf("chained V clocks = %d, want 1", masters)
	}

	// Seed all destination clocks through the same entry policy as normal
	// travel, then isolate the next chained firing from the opening burst.
	if err := g.runWorldPolicy("world.fog_machines", map[string]any{
		"source_level_id":      1,
		"destination_level_id": stage.levelID,
		"elapsed_aut":          int64(0),
		"enter":                true,
	}); err != nil {
		t.Fatal(err)
	}

	clouds := g.scripts.Components()["world.cloud"]

	for _, entity := range clouds.Entities() {
		g.world.DestroyEntity(entity)
	}

	store := g.scripts.Components()["world.fog_machine"]
	var sourcesX []int64
	var sourcesY []int64

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		chain, _ := state.Get("chain")

		if chain != "V" {
			continue
		}

		xs, _ := state.Get("positions_x")
		ys, _ := state.Get("positions_y")
		xBytes, err := json.Marshal(xs)

		if err != nil {
			t.Fatal(err)
		}

		yBytes, err := json.Marshal(ys)

		if err != nil {
			t.Fatal(err)
		}

		if err := json.Unmarshal(xBytes, &sourcesX); err != nil {
			t.Fatal(err)
		}

		if err := json.Unmarshal(yBytes, &sourcesY); err != nil {
			t.Fatal(err)
		}

		if err := state.Set("countdown_aut", int64(1)); err != nil {
			t.Fatal(err)
		}
	}

	if err := g.runWorldPolicy("world.fog_machines", map[string]any{
		"source_level_id":      stage.levelID,
		"destination_level_id": stage.levelID,
		"elapsed_aut":          int64(10),
		"enter":                false,
	}); err != nil {
		t.Fatal(err)
	}

	for index, x := range sourcesX {
		found := false

		for _, entity := range clouds.Entities() {
			state, _ := clouds.Get(entity)
			cloudX, _ := state.Get("x")
			cloudY, _ := state.Get("y")

			if math.Abs(float64(cloudX.(int64)-x)) <= 15 &&
				math.Abs(float64(cloudY.(int64)-sourcesY[index])) <= 15 {
				found = true
				break
			}
		}

		if !found {
			t.Fatalf("chained V source %d emitted no nearby cloud", index)
		}
	}
}

// The source small listener uses a circular 12-cell range. It warns and
// announces the burst inside that radius, and stays silent outside it.
func TestVolcanoSmallFogListenerRange(t *testing.T) {
	g := newGeneratedTestGame(t, 88167)
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "volcano_lake",
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

	store := g.scripts.Components()["world.fog_machine"]
	var targetX int64
	var targetY int64
	selected := false

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		listener, _ := state.Get("listener")

		if listener != "volcano.small" {
			continue
		}

		if !selected {
			xValue, _ := state.Get("x")
			yValue, _ := state.Get("y")
			targetX = xValue.(int64)
			targetY = yValue.(int64)
			selected = true
		} else if err := state.Set("listener", ""); err != nil {
			t.Fatal(err)
		}
	}

	if !selected {
		t.Fatal("Volcano lake has no small fog listener")
	}

	check := func(x, y int, countdown int64, want string) {
		t.Helper()

		if _, err := g.stores.Positions.Set(g.player, ecs.Position{
			LevelID: stage.levelID,
			X:       x,
			Y:       y,
		}); err != nil {
			t.Fatal(err)
		}

		for _, entity := range store.Entities() {
			state, _ := store.Get(entity)
			listener, _ := state.Get("listener")

			if listener != "volcano.small" {
				continue
			}

			if err := state.Set("countdown_aut", countdown); err != nil {
				t.Fatal(err)
			}

			if err := state.Set("warned", false); err != nil {
				t.Fatal(err)
			}
		}

		g.turn.Events = nil

		if err := g.runWorldPolicy("world.fog_machines", map[string]any{
			"source_level_id":      stage.levelID,
			"destination_level_id": stage.levelID,
			"elapsed_aut":          int64(1),
			"enter":                false,
		}); err != nil {
			t.Fatal(err)
		}

		messages := make([]string, 0, len(g.turn.Events))

		for _, event := range g.turn.Events {
			messages = append(messages, event.Text)
		}

		if want == "" && len(messages) != 0 {
			t.Fatalf("unexpected distant warning: %v", messages)
		}

		if want != "" && !strings.Contains(strings.Join(messages, "\n"), want) {
			t.Fatalf("warning = %v, want %q", messages, want)
		}
	}

	check(-100, -100, 30, "")
	check(int(targetX), int(targetY), 30, "scent of sulphur")
	check(-100, -100, 1, "")
	check(int(targetX), int(targetY), 1, "belching forth lava")
}

// A large eruption has the source near and distant firing variants.
// Visibility, rather than the small machine's distance rule, selects one.
func TestVolcanoLargeFogListenerVisibility(t *testing.T) {
	g := newGeneratedTestGame(t, 88169)
	stage, err := g.stageGeneratedLevel(
		"world.generate_volcano_level",
		map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "volcano_bunker",
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

	store := g.scripts.Components()["world.fog_machine"]
	var sourceX int64
	var sourceY int64
	selected := false

	for _, entity := range store.Entities() {
		state, _ := store.Get(entity)
		listener, _ := state.Get("listener")

		if listener != "volcano.large" {
			continue
		}

		if !selected {
			xValue, _ := state.Get("x")
			yValue, _ := state.Get("y")
			sourceX = xValue.(int64)
			sourceY = yValue.(int64)
			selected = true
		} else if err := state.Set("listener", ""); err != nil {
			t.Fatal(err)
		}
	}

	if !selected {
		t.Fatal("Volcano bunker has no large listener")
	}

	farX := -1
	farY := -1

	for y, row := range g.levels[stage.levelID].Cells() {
		for x := range row {
			if !g.levels[stage.levelID].Walkable(x, y) ||
				math.Abs(float64(int64(x)-sourceX)) <= 7 &&
					math.Abs(float64(int64(y)-sourceY)) <= 7 {
				continue
			}

			farX = x
			farY = y
			break
		}

		if farX >= 0 {
			break
		}
	}

	if farX < 0 {
		t.Fatal("Volcano bunker has no distant walkable cell")
	}

	check := func(x, y int, want string) {
		t.Helper()

		if _, err := g.stores.Positions.Set(g.player, ecs.Position{
			LevelID: stage.levelID,
			X:       x,
			Y:       y,
		}); err != nil {
			t.Fatal(err)
		}

		for _, entity := range store.Entities() {
			state, _ := store.Get(entity)
			listener, _ := state.Get("listener")

			if listener == "volcano.large" {
				if err := state.Set("countdown_aut", int64(1)); err != nil {
					t.Fatal(err)
				}
			}
		}

		g.turn.Events = nil

		if err := g.runWorldPolicy("world.fog_machines", map[string]any{
			"source_level_id":      stage.levelID,
			"destination_level_id": stage.levelID,
			"elapsed_aut":          int64(1),
			"enter":                false,
		}); err != nil {
			t.Fatal(err)
		}

		messages := make([]string, 0, len(g.turn.Events))

		for _, event := range g.turn.Events {
			messages = append(messages, event.Text)
		}

		if !strings.Contains(strings.Join(messages, "\n"), want) {
			t.Fatalf("large eruption = %v, want %q", messages, want)
		}
	}

	check(int(sourceX), int(sourceY),
		"The volcano comes to life with a roar!")
	check(farX, farY,
		"In the distance, the volcano erupts with a roar.")
}
