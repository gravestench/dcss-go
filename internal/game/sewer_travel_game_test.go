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

// Every bundled destination goes through the same staged generation and
// ECS population transaction used by live entry. A requested layout is an
// ordinary mod API; the weighted selector remains the default for play.
func TestSewerAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/sewer")

	if err != nil {
		t.Fatal(err)
	}

	if len(files) != 19 {
		t.Fatalf("expected 19 source Sewer maps, got %d", len(files))
	}

	g := newGeneratedTestGame(t, 88128)

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")
		t.Run(id, func(t *testing.T) {
			stage, err := g.stageGeneratedLevel(
				"world.generate_sewer_level",
				map[string]any{
					"species_id":  "SP_HUMAN",
					"player_name": "Tester",
					"layout_id":   id,
				},
			)

			if err != nil {
				t.Fatal(err)
			}

			floor := g.levels[stage.levelID]

			if floor == nil || floor.BranchID != "BRANCH_SEWER" ||
				floor.VaultID() != id || len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Sewer map %s lost its source records", id)
			}

			if err := stage.rollback(); err != nil {
				t.Fatal(err)
			}
		})
	}
}

// A rejected destination identity exercises the generic stage rollback
// after source map generation and population have already succeeded.
func TestSewerRejectedStagedMapRollsBack(t *testing.T) {
	g := newGeneratedTestGame(t, 88126)
	placeSewerPortalForTest(t, g)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Sewer visitor has no position")
	}

	plan := map[string]any{
		"operation":     "enter",
		"commit_policy": "world.sewer.commit_travel",
		"source": map[string]any{
			"level_id": int64(position.LevelID),
			"x":        int64(position.X),
			"y":        int64(position.Y),
		},
		"generate_policy": "world.generate_sewer_level",
		"generation_input": map[string]any{
			"species_id":  "SP_HUMAN",
			"player_name": "Tester",
		},
		"expected_branch_id": "BRANCH_SEWER",
		"expected_level_id":  int64(999999),
	}

	beforeState := g.Snapshot()
	before, err := json.Marshal(beforeState)

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.prepareLuaPortal(plan, position); err == nil ||
		!strings.Contains(err.Error(), "another floor identity") {
		t.Fatalf("rejected Sewer map returned %v", err)
	}

	afterState := g.Snapshot()
	// Akara does not reuse staged entity IDs after rollback.
	afterState.EntityCursor = beforeState.EntityCursor
	after, err := json.Marshal(afterState)

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(before, after) {
		t.Fatal("rejected Sewer map changed saved state")
	}
}

// Install an authored-style drain under the player. Source corpus tests
// exercise all fifteen entrance maps; this fixture exercises the game
// transaction and save boundary without relying on a chance placement.
func placeSewerPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterSewer)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 600, high = 600, single_timed = true, floor = "expired_portal" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: "portal_sewer_entry_a",
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	ids := append(level.VaultIDs(), "portal_sewer_entry_a")

	if err := level.SetVaultIDs(ids); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.sewer_portal"]

	if _, err := store.Set(entity, map[string]any{
		"level_id":       int64(1),
		"x":              int64(site.x),
		"y":              int64(site.y),
		"vault_id":       "portal_sewer_entry_a",
		"record_index":   int64(len(level.vaultRecords)),
		"duration_turns": int64(600),
		"created_aut":    int64(g.currentAut),
		"expires_aut":    int64(g.currentAut) + 6000,
		"spent":          false,
		"announced":      false,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// Entry selects a real Sewer map and population, while exit returns to
// the saved drain and retires every temporary floor entity.
func TestSewerEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88123)
	origin := placeSewerPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("Sewer visitor has no position")
	}

	floor := g.levels[position.LevelID]

	if floor == nil || floor.BranchID != "BRANCH_SEWER" ||
		floor.VaultID() == "" ||
		g.levels[1].terrain[origin.y][origin.x] !=
			terrain.ExpiredPortal {
		t.Fatalf("Sewer entry lost its map or spent drain: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("active Sewer save could not restore: %v", err)
	}

	g = restored
	position, found = g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("restored Sewer visitor has no position")
	}

	floor = g.levels[position.LevelID]

	var exit point
	found = false

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitSewer {
				exit = point{x: x, y: y}
				found = true
				break
			}
		}

		if found {
			break
		}
	}

	if !found {
		t.Fatal("selected Sewer map has no exit")
	}

	if err := floor.MoveActor(g.player, exit.x, exit.y); err != nil {
		t.Fatal(err)
	}

	floorID := floor.ID

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.LevelID != 1 || position.X != origin.x ||
		position.Y != origin.y || g.levels[floorID] != nil {
		t.Fatalf("Sewer did not return and retire: %+v", position)
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("exited Sewer save could not restore: %v", err)
	}
}

// A monster on the saved drain must not silently redirect Sewer return to
// a neighboring Dungeon tile. The player can retry once the cell clears.
func TestSewerReturnWaitsForExactOutsideCell(t *testing.T) {
	g := newGeneratedTestGame(t, 88130)
	origin := placeSewerPortalForTest(t, g)

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
			if feature == terrain.ExitSewer {
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

	if err != nil || result.Spent != 0 ||
		g.levels[floor.ID] == nil {
		t.Fatalf("occupied outside drain allowed Sewer exit: %+v, %v",
			result, err)
	}
}

// A drain expires at its fixed source deadline even while the player acts
// on another floor. The clock jump isolates expiry from 600 ordinary turns;
// it is deliberately not a restorable full-game snapshot.
func TestSewerGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88124)
	origin := placeSewerPortalForTest(t, g)

	descendGeneratedTo(t, g, 2)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] !=
		terrain.ExpiredPortal {
		t.Fatal("inactive Sewer drain survived its deadline")
	}

}

// Advance the ordinary scheduler rather than jumping its clock. This
// proves an expired drain can be restored alongside all unrelated timers.
func TestSewerExpiredSaveRestores(t *testing.T) {
	g := newGeneratedTestGame(t, 88131)
	origin := placeSewerPortalForTest(t, g)

	// Remove ordinary test-floor monsters so this timer test does not turn
	// into a combat or player-death test over six hundred waits.
	for _, entity := range g.world.Entities() {
		if entity == g.player {
			continue
		}

		position, found := g.stores.Positions.Get(entity)

		if !found || position.LevelID != 1 {
			continue
		}

		actor, occupied := g.levels[1].ActorAt(position.X, position.Y)

		if !occupied || actor != entity {
			continue
		}

		if err := g.levels[1].RemoveActor(entity); err != nil {
			t.Fatal(err)
		}

		for _, item := range g.stores.CarriedBy.Entities() {
			carrier, _ := g.stores.CarriedBy.Get(item)

			if carrier.Holder == entity {
				g.world.DestroyEntity(item)
			}
		}

		g.world.DestroyEntity(entity)
	}

	for turn := 0; turn < 600; turn++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if g.levels[1].terrain[origin.y][origin.x] !=
		terrain.ExpiredPortal {
		t.Fatal("source Sewer drain survived 600 normal turns")
	}

	if _, err := Restore(g.Snapshot()); err != nil {
		t.Fatalf("expired Sewer save could not restore: %v", err)
	}
}

// A command accepted just before expiry completes its travel before the
// timer system mutates the drain during that same player action.
func TestSewerGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88127)
	origin := placeSewerPortalForTest(t, g)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found || g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_SEWER" ||
		g.levels[1].terrain[origin.y][origin.x] !=
			terrain.ExpiredPortal {
		t.Fatalf("accepted Sewer entry lost its deadline travel: %+v",
			position)
	}
}

// Changing either side of the source marker and ECS clock join must fail
// restore, even when the edited value looks like another legal duration.
func TestSewerRestoreRejectsForgedDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88125)
	placeSewerPortalForTest(t, g)
	changed := g.Snapshot()

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			component := &changed.Entities[index].Dynamic[part]

			if component.Schema == "world.sewer_portal" {
				component.Values["expires_aut"] =
					json.RawMessage("7000")
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Sewer") {
		t.Fatalf("forged Sewer deadline was accepted: %v", err)
	}
}

// The selected map, outside pointer, and authored source record are three
// separate saved witnesses. Coordinated ID edits cannot relabel a floor.
func TestSewerRestoreRejectsForgedVisitAndMap(t *testing.T) {
	g := newGeneratedTestGame(t, 88129)
	placeSewerPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	t.Run("outside return site", func(t *testing.T) {
		changed := g.Snapshot()

		for index := range changed.Entities {
			for part := range changed.Entities[index].Dynamic {
				entry := &changed.Entities[index].Dynamic[part]

				if entry.Schema == "character.sewer_visit" {
					entry.Values["origin_x"] = json.RawMessage("999")
				}
			}
		}

		if _, err := Restore(changed); err == nil ||
			!strings.Contains(err.Error(), "Sewer") {
			t.Fatalf("forged Sewer return was accepted: %v", err)
		}
	})

	t.Run("selected source map", func(t *testing.T) {
		changed := g.Snapshot()
		alternate := "sewer_kobolds"

		for index := range changed.Levels {
			if changed.Levels[index].BranchID != "BRANCH_SEWER" {
				continue
			}

			if changed.Levels[index].VaultID == alternate {
				alternate = "sewer_sea"
			}

			changed.Levels[index].VaultID = alternate
			changed.Levels[index].VaultIDs = append(
				changed.Levels[index].VaultIDs, alternate)
		}

		encodedID, err := json.Marshal(alternate)

		if err != nil {
			t.Fatal(err)
		}

		for index := range changed.Entities {
			for part := range changed.Entities[index].Dynamic {
				entry := &changed.Entities[index].Dynamic[part]

				if entry.Schema == "character.sewer_visit" {
					entry.Values["vault_id"] = encodedID
				}
			}
		}

		if _, err := Restore(changed); err == nil ||
			!strings.Contains(err.Error(), "saved Sewer") {
			t.Fatalf("forged Sewer map was accepted: %v", err)
		}
	})

	t.Run("authored marker", func(t *testing.T) {
		changed := g.Snapshot()

		for index := range changed.Levels {
			if changed.Levels[index].ID != 1 {
				continue
			}

			for record := range changed.Levels[index].VaultRecords {
				candidate := &changed.Levels[index].VaultRecords[record]

				if candidate.SourceID == "portal_sewer_entry_a" &&
					candidate.Kind == vault.KindMarker {
					candidate.SourceID = "portal_sewer_entry_b"
				}
			}
		}

		if _, err := Restore(changed); err == nil ||
			!strings.Contains(err.Error(), "Sewer") {
			t.Fatalf("forged Sewer marker was accepted: %v", err)
		}
	})
}
