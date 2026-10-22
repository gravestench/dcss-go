package game

import (
	"bytes"
	"encoding/json"
	"os"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Every source destination must survive the actual staged level and ECS
// population path. This catches a map that parses but drops monsters,
// loot, or its authored identity before the portal can open it.
func TestOssuaryAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/ossuary")

	if err != nil {
		t.Fatal(err)
	}

	if len(files) != 20 {
		t.Fatalf("expected 20 source Ossuary maps, got %d", len(files))
	}

	g := newGeneratedTestGame(t, 88129)

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")
		t.Run(id, func(t *testing.T) {
			stage, err := g.stageGeneratedLevel(
				"world.generate_ossuary_level",
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
				floor.BranchID != "BRANCH_OSSUARY" ||
				floor.VaultID() != id ||
				len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Ossuary %s lost source records", id)
			}

			exits := 0

			for _, row := range floor.Cells() {
				for _, cell := range row {
					if cell == terrain.ID("DNGN_EXIT_OSSUARY") {
						exits++
					}
				}
			}

			if exits == 0 {
				t.Fatalf("populated Ossuary %s has no return exit", id)
			}

		})
	}
}

// The entrance fixture preserves the source marker and its separately
// materialized ECS clock, matching what Dungeon population will create.
func placeOssuaryPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterOssuary)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 600, high = 600, single_timed = true, floor = "expired_portal" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "enter_ossuary_1",
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	ids := append(level.VaultIDs(), "enter_ossuary_1")

	if err := level.SetVaultIDs(ids); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.ossuary_portal"]

	if store == nil {
		t.Fatal("Ossuary ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(1),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        "enter_ossuary_1",
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
func TestOssuaryEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88132)
	origin := placeOssuaryPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Ossuary visitor has no position")
	}

	floor := g.levels[position.LevelID]

	if floor == nil ||
		floor.BranchID != "BRANCH_OSSUARY" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("Ossuary entry lost its floor or gate: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Ossuary visit could not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor = g.levels[position.LevelID]

	var exit point

	found = false

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitOssuary {
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
		t.Fatal("selected Ossuary map has no exit")
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
		t.Fatalf("Ossuary did not return and retire: %+v", position)
	}
}

// A stage rejected after generation must leave the outside gate, RNG,
// entities, and player unchanged so the same gate remains usable.
func TestOssuaryRejectedStagedMapRollsBack(t *testing.T) {
	g := newGeneratedTestGame(t, 88133)
	placeOssuaryPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.ossuary.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_ossuary_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
		},
		"expected_branch_id": "BRANCH_OSSUARY",
		"expected_level_id":  int64(999999),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), "another floor identity") {
		t.Fatalf("rejected Ossuary map returned %v", err)
	}

	afterState := g.Snapshot()

	afterState.EntityCursor = beforeState.EntityCursor

	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("rejected Ossuary map changed saved state")
	}
}

// A blocked return cell must keep the temporary floor and cost no time.
// The player can leave later when the outside cell becomes free.
func TestOssuaryReturnWaitsForExactOutsideCell(t *testing.T) {
	g := newGeneratedTestGame(t, 88134)
	origin := placeOssuaryPortalForTest(t, g)

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
			if feature == terrain.ExitOssuary {
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
		t.Fatalf("blocked Ossuary return changed the visit: %+v, %v",
			result, err)
	}
}

// Global action time expires a gate even while its Dungeon floor is
// inactive. This clock jump isolates the boundary from ordinary combat.
func TestOssuaryGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88135)
	origin := placeOssuaryPortalForTest(t, g)

	descendGeneratedTo(t, g, 2)

	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatal("inactive Ossuary gate survived its deadline")
	}
}

// Entering on the last valid action completes before the timer system
// spends the gate. The subsequent outside feature is still expired.
func TestOssuaryGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88136)
	origin := placeOssuaryPortalForTest(t, g)

	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_OSSUARY" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("accepted Ossuary entry lost deadline travel: %+v",
			position)
	}
}

// The authored duration is fixed in the source marker. A saved clock with
// another deadline must fail restore even if the new duration is in range.
func TestOssuaryRestoreRejectsForgedDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88137)
	placeOssuaryPortalForTest(t, g)
	changed := g.Snapshot()

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			entry := &changed.Entities[index].Dynamic[part]

			if entry.Schema == "world.ossuary_portal" {
				entry.Values["expires_aut"] = json.RawMessage("7000")
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Ossuary") {
		t.Fatalf("forged Ossuary deadline was accepted: %v", err)
	}
}

// The source boxes map links every a/b wall to one trigger group. A save
// with only one wall opened cannot be the result of that atomic event.
func TestOssuaryRestoreRejectsPartlyOpenedBoxes(t *testing.T) {
	g := newGeneratedTestGame(t, 88138)
	placeOssuaryPortalForTest(t, g)
	position, _ := g.stores.Positions.Get(g.player)
	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.ossuary.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_ossuary_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
			"layout_id":   "ossuary_boxes_badplayer",
		},
		"expected_branch_id": "BRANCH_OSSUARY",
		"expected_level_id":  int64(2901),
	}

	portal, err := g.prepareLuaPortal(plan, position)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := portal.commit(g); err != nil {
		t.Fatal(err)
	}

	if err := g.runWorldPolicy("world.zot_clock", map[string]any{
		"level_id":    int64(2901),
		"branch_id":   "BRANCH_OSSUARY",
		"elapsed_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	clean := g.Snapshot()

	if _, err := Restore(clean); err != nil {
		t.Fatalf("authored boxes map failed to restore: %v", err)
	}

	changed := g.Snapshot()
	opened := false

	for levelIndex := range changed.Levels {
		level := &changed.Levels[levelIndex]

		if level.BranchID != "BRANCH_OSSUARY" {
			continue
		}

		for _, record := range level.VaultRecords {
			if record.Identity != "ossuary_disappearing_wall" {
				continue
			}

			level.Cells[record.Y][record.X] = terrain.Floor
			opened = true
			break
		}
	}

	if !opened {
		t.Fatal("source boxes map has no disappearing wall")
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Ossuary") {
		t.Fatalf("partly opened boxes were accepted: %v", err)
	}
}
