package game

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

const desolationTestGateID = "portal_desolation_entry_ruin"

const desolationSlugVaultID = "portal_desolation_entry_nicolae_slug"

// Each complete source MAP must reach ECS population, retain its nested
// ruins, and expose at least one live exit. Optional text output lets a
// reader inspect all three generated floors and their outside connection.
func TestDesolationAllSourceMapsPopulate(t *testing.T) {
	files, err := os.ReadDir("../modfs/builtin/vaults/desolation")

	if err != nil {
		t.Fatal(err)
	}

	if len(files) != 3 {
		t.Fatalf("expected three source Desolation maps, got %d", len(files))
	}

	g := newGeneratedTestGame(t, 88143)
	directory := os.Getenv("CRAWL_DESOLATION_SNAPSHOT_DIR")
	var index strings.Builder
	var outside point

	if directory != "" {
		if err := os.MkdirAll(directory, 0o755); err != nil {
			t.Fatal(err)
		}

		outside = placeDesolationPortalForTest(t, g)
		index.WriteString("Desolation of Salt source layouts, seed 88143\n")
		index.WriteString("Coordinates are zero-based, origin at top left.\n")
		index.WriteString("Every return arch points to the saved outside gate.\n\n")
	}

	for _, file := range files {
		id := strings.TrimSuffix(file.Name(), ".des")

		t.Run(id, func(t *testing.T) {
			stage, err := g.stageGeneratedLevel(
				"world.generate_desolation_level",
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
				floor.BranchID != "BRANCH_DESOLATION" ||
				floor.VaultID() != id ||
				len(floor.VaultRecords()) == 0 {
				t.Fatalf("populated Desolation %s lost source records", id)
			}

			exits := 0

			for _, row := range floor.Cells() {
				for _, cell := range row {
					if cell == terrain.ExitDesolation {
						exits++
					}
				}
			}

			if exits == 0 {
				t.Fatalf("populated Desolation %s has no return exit", id)
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
					t.Fatal("staged Desolation floor is absent from snapshot")
				}

				var connections strings.Builder

				for y, row := range floor.Cells() {
					for x, cell := range row {
						if cell == terrain.ExitDesolation {
							fmt.Fprintf(&connections,
								"Desolation exit (%d,%d) -> Dungeon:1 (%d,%d), exact outside gate\n",
								x, y, outside.x, outside.y)
						}
					}
				}

				body := formatLevelTextSnapshot(record, nil)
				body += connections.String()

				if err := os.WriteFile(filepath.Join(directory, id+".txt"),
					[]byte(body), 0o644); err != nil {
					t.Fatal(err)
				}

				fmt.Fprintf(&index, "%s  %s.txt\n", id, id)
				ruins := strings.Join(floor.VaultIDs()[1:], ", ")

				if ruins == "" {
					ruins = "none"
				}

				fmt.Fprintf(&index, "  ruins: %s\n", ruins)
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

// The test gate has the same source marker and ECS clock that Dungeon
// population creates. Its fixed duration and source ID protect restore.
func placeDesolationPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterDesolation)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 600, high = 600, single_timed = true, floor = "expired_portal" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: desolationTestGateID,
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.SetVaultIDs(append(level.VaultIDs(),
		desolationTestGateID)); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.desolation_portal"]

	if store == nil {
		t.Fatal("Desolation ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(1),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        desolationTestGateID,
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

// The visitor returns to the exact gate cell after a save round trip.
func TestDesolationEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88144)
	origin := placeDesolationPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_DESOLATION" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("Desolation entry lost its floor or gate: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Desolation visit could not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	var exit point
	found = false

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitDesolation {
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
		t.Fatal("Desolation floor has no exit")
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
		t.Fatalf("Desolation did not return and retire: %+v", position)
	}
}

// Global action time closes a gate even when its outside floor is inactive.
func TestDesolationGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88145)
	origin := placeDesolationPortalForTest(t, g)
	descendGeneratedTo(t, g, 2)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatal("inactive Desolation gate survived its deadline")
	}

	if _, err := g.scripts.Policy("save.validate_desolation_portals",
		map[string]any{
			"levels": g.vaultValidationLevels(),
		}); err != nil {
		t.Fatalf("expired outside gate failed Desolation validation: %v", err)
	}
}

// An accepted stair action at the deadline commits before the timer system
// expires the old outside gate. The saved visitor can still return later.
func TestDesolationGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88146)
	origin := placeDesolationPortalForTest(t, g)

	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_DESOLATION" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("deadline travel did not enter Desolation: %+v", position)
	}
}

// Restore joins the source marker's drawn duration to the ECS deadline.
// A different saved deadline cannot invent extra time for the gateway.
func TestDesolationRestoreRejectsForgedDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88147)
	placeDesolationPortalForTest(t, g)
	changed := g.Snapshot()

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			entry := &changed.Entities[index].Dynamic[part]

			if entry.Schema == "world.desolation_portal" {
				entry.Values["expires_aut"] = json.RawMessage("7000")
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Desolation") {
		t.Fatalf("forged Desolation deadline was accepted: %v", err)
	}
}

// Source delayed_decay keeps the slug's authored corpse fresh until its
// original square enters sight. From then on the ordinary corpse clock owns
// its lifetime, including the transition from body to skeleton.
func TestDesolationSlugCorpseStartsDecayOnSight(t *testing.T) {
	g := newGeneratedTestGame(t, 88148)
	player, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	site := ecs.Position{
		LevelID: player.LevelID,
		X:       player.X,
		Y:       player.Y,
	}

	corpseID := testCorpseAt(t, g, "CORPSE_BODY", site)
	corpse, _ := g.stores.Corpses.Get(corpseID)

	corpse.MonsterID = "MONS_DART_SLUG"
	corpse.NeverDecays = true

	if _, err := g.stores.Corpses.Set(corpseID, *corpse); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[site.LevelID].AddVaultRecord(vault.Record{
		Kind:     vault.KindDelayedDecay,
		SourceID: desolationSlugVaultID,
		X:        site.X,
		Y:        site.Y,
	}); err != nil {
		t.Fatal(err)
	}

	origins := g.scripts.Components()["vault.origin"]

	if _, err := origins.Set(corpseID, map[string]any{
		"level_id":     int64(site.LevelID),
		"vault_id":     desolationSlugVaultID,
		"kind_id":      "CORPSE_BODY",
		"record_index": int64(1),
		"occurrence":   int64(1),
		"spawn_x":      int64(site.X),
		"spawn_y":      int64(site.Y),
	}); err != nil {
		t.Fatal(err)
	}

	if err := g.runWorldPolicy("world.age_corpses", map[string]any{
		"level_id": site.LevelID,
		"elapsed":  200,
	}); err != nil {
		t.Fatal(err)
	}

	corpse, _ = g.stores.Corpses.Get(corpseID)

	if !corpse.NeverDecays || corpse.Freshness != 110 {
		t.Fatalf("unseen source corpse aged: %+v", corpse)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	corpse, _ = g.stores.Corpses.Get(corpseID)

	if corpse.NeverDecays {
		t.Fatal("sighted source corpse remained preserved")
	}

	if err := g.runWorldPolicy("world.age_corpses", map[string]any{
		"level_id": site.LevelID,
		"elapsed":  200,
	}); err != nil {
		t.Fatal(err)
	}

	corpse, _ = g.stores.Corpses.Get(corpseID)

	if corpse.Freshness != 100 {
		t.Fatalf("sighted source corpse failed to rot: %+v", corpse)
	}
}
