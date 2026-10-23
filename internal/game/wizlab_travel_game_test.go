package game

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Every source destination must survive the actual staged level and ECS
// population path. This catches a map that parses but drops monsters,
// loot, or its authored identity before the portal can open it.
func TestWizlabAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/wizlab")

	if err != nil {
		t.Fatal(err)
	}

	if len(files) != 15 {
		t.Fatalf("expected 15 source Wizlab maps, got %d", len(files))
	}

	g := newGeneratedTestGame(t, 88129)
	directory := os.Getenv("CRAWL_WIZLAB_SNAPSHOT_DIR")
	var index strings.Builder
	var outside point

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		outside = placeWizlabPortalForTest(t, g)
		index.WriteString("Wizard Labs source layouts, seed 88129\n")
		index.WriteString("Coordinates are zero-based, origin at top left.\n")
		index.WriteString("Every return arch points to the exact outside gate.\n\n")
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")
		t.Run(id, func(t *testing.T) {
			stage, err := g.stageGeneratedLevel(
				"world.generate_wizlab_level",
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

			if floor == nil ||
				floor.BranchID != "BRANCH_WIZLAB" ||
				floor.VaultID() != id ||
				len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Wizlab %s lost source records", id)
			}

			exits := 0

			for _, row := range floor.Cells() {
				for _, cell := range row {
					if cell == terrain.ID("DNGN_EXIT_WIZLAB") {
						exits++
					}
				}
			}

			if exits == 0 {
				t.Fatalf("populated Wizlab %s has no return exit", id)
			}

			if _, err := g.scripts.Policy("save.validate_wizlab_events",
				map[string]any{
					"levels": g.vaultValidationLevels(),
				}); err != nil {
				t.Fatalf("%s source events do not round-trip: %v", id, err)
			}

			if directory != "" {
				var record save.LevelRecord

				for _, candidate := range g.Snapshot().Levels {
					if candidate.ID == floor.ID {
						record = candidate
						break
					}
				}

				if record.ID != floor.ID {
					t.Fatal("staged Wizard Lab is absent from snapshot")
				}

				var connections strings.Builder

				for y, row := range floor.Cells() {
					for x, cell := range row {
						if cell == terrain.ExitWizlab {
							fmt.Fprintf(&connections,
								"Wizard Lab exit (%d,%d) -> Dungeon:1 (%d,%d), exact outside gate\n",
								x, y, outside.x, outside.y)
						}
					}
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
			}

		})
	}

	if directory != "" {
		if err := os.WriteFile(filepath.Join(directory, "index.txt"),
			[]byte(index.String()), 0o644); err != nil {
			t.Fatal(err)
		}
	}
}

// The entrance fixture preserves the source marker and its separately
// materialized ECS clock, matching what Dungeon population will create.
func placeWizlabPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterWizlab)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 600, high = 600, single_timed = true, floor = "stone_arch" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "mu_enter_wizlab_1",
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	ids := append(level.VaultIDs(), "mu_enter_wizlab_1")

	if err := level.SetVaultIDs(ids); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.wizlab_portal"]

	if store == nil {
		t.Fatal("Wizlab ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(1),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        "mu_enter_wizlab_1",
		"record_index":    int64(len(level.vaultRecords)),
		"duration_turns":  int64(600),
		"created_aut":     int64(g.currentAut),
		"expires_aut":     int64(g.currentAut) + 6000,
		"spent":           false,
		"announced":       false,
		"next_notice_aut": int64(g.currentAut) + 500,
		"final_warning":   false,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// Entry stages a real source map, and returning after restore uses the
// original gate cell rather than choosing another Dungeon landing.
func TestWizlabEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88132)
	origin := placeWizlabPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Wizlab visitor has no position")
	}

	floor := g.levels[position.LevelID]

	if floor == nil ||
		floor.BranchID != "BRANCH_WIZLAB" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("Wizlab entry lost its floor or gate: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Wizlab visit could not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor = g.levels[position.LevelID]

	var exit point

	found = false

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitWizlab {
				exit = point{
					x: x,
					y: y,
				}

				found = true
				break
			}
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatal("selected Wizlab map has no exit")
	}

	if err := floor.MoveActor(g.player, exit.x, exit.y); err != nil {
		t.Fatal(err)
	}

	floorID := floor.ID

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.LevelID != 1 ||
		position.X != origin.x ||
		position.Y != origin.y ||
		g.levels[floorID] != nil {
		t.Fatalf("Wizlab did not return and retire: %+v", position)
	}
}

// A stage rejected after generation must leave the outside gate, RNG,
// entities, and player unchanged so the same gate remains usable.
func TestWizlabRejectedStagedMapRollsBack(t *testing.T) {
	g := newGeneratedTestGame(t, 88133)
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
		},
		"expected_branch_id": "BRANCH_WIZLAB",
		"expected_level_id":  int64(999999),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), "another floor identity") {
		t.Fatalf("rejected Wizlab map returned %v", err)
	}

	afterState := g.Snapshot()

	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("rejected Wizlab map changed saved state")
	}
}

// A blocked return cell must keep the temporary floor and cost no time.
// The player can leave later when the outside cell becomes free.
func TestWizlabReturnWaitsForExactOutsideCell(t *testing.T) {
	g := newGeneratedTestGame(t, 88134)
	origin := placeWizlabPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	blocker := spawnWormForTest(t, g, 1)

	if err := g.levels[1].MoveActor(blocker, origin.x, origin.y); err != nil {
		t.Fatal(err)
	}

	for y, row := range floor.Cells() {
		found := false

		for x, feature := range row {
			if feature == terrain.ExitWizlab {
				if err := floor.MoveActor(g.player, x, y); err != nil {
					t.Fatal(err)
				}

				found = true
				break
			}
		}

		if found {
			break
		}
	}

	result, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		result.Spent != 0 ||
		g.levels[floor.ID] == nil {
		t.Fatalf("blocked Wizlab return changed the visit: %+v, %v",
			result, err)
	}
}

// Global action time expires a gate even while its Dungeon floor is
// inactive. This clock jump isolates the boundary from ordinary combat.
func TestWizlabGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88135)
	origin := placeWizlabPortalForTest(t, g)

	descendGeneratedTo(t, g, 2)

	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatal("inactive Wizlab gate survived its deadline")
	}
}

// Entering on the last valid action completes before the timer system
// spends the gate. The subsequent outside feature is still expired.
func TestWizlabGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88136)
	origin := placeWizlabPortalForTest(t, g)

	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_WIZLAB" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("accepted Wizlab entry lost deadline travel: %+v",
			position)
	}
}

// The authored duration is fixed in the source marker. A saved clock with
// another deadline must fail restore even if the new duration is in range.
func TestWizlabRestoreRejectsForgedDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88137)
	placeWizlabPortalForTest(t, g)
	changed := g.Snapshot()

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			entry := &changed.Entities[index].Dynamic[part]

			if entry.Schema == "world.wizlab_portal" {
				entry.Values["expires_aut"] = json.RawMessage("7000")
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Wizard Lab") {
		t.Fatalf("forged Wizlab deadline was accepted: %v", err)
	}
}

// A saved wave count must agree with the source G grave bitset. Changing
// only the ECS counter cannot invent previously awakened monsters.
func TestWizlabRestoreRejectsForgedGraveCount(t *testing.T) {
	g := newGeneratedTestGame(t, 88132)
	placeWizlabPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	changed := g.Snapshot()
	found := false

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			entry := &changed.Entities[index].Dynamic[part]

			if entry.Schema == "world.wizlab_zonguldrok" {
				entry.Values["count"] = json.RawMessage("10")
				found = true
			}
		}
	}

	if !found {
		t.Fatal("seed did not select Zonguldrok's source room")
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Zonguldrok") {
		t.Fatalf("forged Wizard Lab grave count was accepted: %v", err)
	}
}
