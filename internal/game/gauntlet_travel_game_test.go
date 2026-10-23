package game

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

const gauntletTestGateID = "gauntlet_entry_generic"

// Create the same typed gate and saved ECS clock that population makes
// from the source O marker. The clock starts on the outside floor.
func placeGauntletPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterGauntlet)
	level := g.levels[1]
	identity := `lua:timed_marker { low = 400, high = 400, single_timed = true, floor = "stone_arch" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: gauntletTestGateID,
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.SetVaultIDs(append(level.VaultIDs(),
		gauntletTestGateID)); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.gauntlet_portal"]

	if store == nil {
		t.Fatal("Gauntlet ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(1),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        gauntletTestGateID,
		"record_index":    int64(len(level.vaultRecords)),
		"duration_turns":  int64(400),
		"created_aut":     int64(g.currentAut),
		"expires_aut":     int64(g.currentAut) + 4000,
		"spent":           false,
		"announced":       false,
		"next_notice_aut": int64(g.currentAut) + 500,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// An accepted gate enters one staged source floor. Any return arch sends
// the visitor to the exact outside cell and retires the temporary floor.
func TestGauntletEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 99144)
	origin := placeGauntletPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_GAUNTLET" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatalf("Gauntlet entry lost its floor or gate: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Gauntlet visit could not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	var exit point
	found = false

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature == terrain.ExitGauntlet {
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
		t.Fatal("Gauntlet floor has no return arch")
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
		t.Fatalf("Gauntlet did not return and retire: %+v", position)
	}
}

// The world clock advances on other floors, so returning to an older
// Dungeon floor cannot reset or revive its Gauntlet gate.
func TestGauntletGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 99145)
	origin := placeGauntletPortalForTest(t, g)
	descendGeneratedTo(t, g, 2)
	g.currentAut = 3990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.StoneArch {
		t.Fatal("inactive Gauntlet gate survived its deadline")
	}
}

// Source no_pickup protects arena prizes from monsters. It never prevents
// a player who reached that chamber from taking an authored floor item.
func TestGauntletPrizeIsPlayerPickable(t *testing.T) {
	g := newGeneratedTestGame(t, 99147)
	placeGauntletPortalForTest(t, g)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]
	found := false
	var site point

	for _, record := range floor.VaultRecords() {
		if record.Kind != vault.KindItem || record.Pending {
			continue
		}

		protected := false

		for _, argument := range record.Arguments {
			if argument.Name == "no_pickup" && argument.Bool {
				protected = true
			}
		}

		if !protected {
			continue
		}

		if _, occupied := floor.ActorAt(record.X, record.Y); occupied {
			continue
		}

		for _, entity := range g.stores.Items.Entities() {
			itemPosition, located := g.stores.Positions.Get(entity)

			if located &&
				itemPosition.LevelID == floor.ID &&
				itemPosition.X == record.X &&
				itemPosition.Y == record.Y {
				site = point{
					x: record.X,
					y: record.Y,
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
		t.Fatal("Gauntlet generated no available protected prize")
	}

	if err := floor.MoveActor(g.player, site.x, site.y); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil ||
		result.Spent != 10 {
		t.Fatalf("player could not take Gauntlet prize: %+v, %v",
			result, err)
	}
}

// Restore must reject a deadline that no longer equals the source
// marker's duration plus the gate's original creation time.
func TestGauntletRestoreRejectsForgedDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 99146)
	placeGauntletPortalForTest(t, g)
	changed := g.Snapshot()

	for index := range changed.Entities {
		for part := range changed.Entities[index].Dynamic {
			entry := &changed.Entities[index].Dynamic[part]

			if entry.Schema == "world.gauntlet_portal" {
				entry.Values["expires_aut"] = json.RawMessage("7000")
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(err.Error(), "Gauntlet") {
		t.Fatalf("forged Gauntlet deadline was accepted: %v", err)
	}
}
