package game

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Install the same typed marker and clock that normal vault population
// creates. The fixture isolates travel from Lair generation and spawn odds.
func placeVolcanoPortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterVolcano)
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	const sourceID = "enter_volcano_1"
	const identity = `lua:timed_marker { low = 600, high = 600, ` +
		`single_timed = true, floor = "expired_portal", entity = "tunnel" }`

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: sourceID,
		Identity: identity,
		X:        site.x,
		Y:        site.y,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.SetVaultIDs(append(level.VaultIDs(), sourceID)); err != nil {
		t.Fatal(err)
	}

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["world.volcano_portal"]

	if store == nil {
		t.Fatal("Volcano ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(level.ID),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        sourceID,
		"record_index":    int64(len(level.vaultRecords)),
		"duration_turns":  int64(600),
		"created_aut":     int64(g.currentAut),
		"expires_aut":     int64(g.currentAut) + 6000,
		"spent":           false,
		"closure_reason":  "",
		"announced":       false,
		"next_notice_aut": int64(g.currentAut) + 500,
		"final_warning":   false,
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// The outside clock advances with player actions on another floor.
func TestVolcanoGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88162)
	origin := placeVolcanoPortalForTest(t, g)
	descendGeneratedTo(t, g, 2)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatal("inactive Volcano gate survived its deadline")
	}

}

// The timed source messenger names the avalanche as the noisemaker.
// The tunnel names the entrance, not the sound heard during countdown.
func TestVolcanoGateRumbleNamesAvalanche(t *testing.T) {
	g := newGeneratedTestGame(t, 88168)
	placeVolcanoPortalForTest(t, g)
	g.currentAut = 500

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if !containsEvent(result.Events,
		"You hear a slow rumble of an avalanche of rocks.") {
		t.Fatalf("Volcano notice did not name source sound: %+v",
			result.Events)
	}
}

// Accepted travel wins over the timer event charged for that same action.
func TestVolcanoLastTurnEntry(t *testing.T) {
	g := newGeneratedTestGame(t, 88163)
	placeVolcanoPortalForTest(t, g)
	g.currentAut += 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_VOLCANO" {
		t.Fatalf("accepted Volcano entry lost deadline travel: %+v", position)
	}
}

// The source marker fixes the one lifetime draw. A forged ECS deadline or
// missing visitor must fail restore even when every terrain cell looks valid.
func TestVolcanoRejectsForgedClockAndVisitor(t *testing.T) {
	g := newGeneratedTestGame(t, 88165)
	placeVolcanoPortalForTest(t, g)
	base := g.Snapshot()
	changed := false

	for entityIndex := range base.Entities {
		for stateIndex := range base.Entities[entityIndex].Dynamic {
			state := &base.Entities[entityIndex].Dynamic[stateIndex]

			if state.Schema == "world.volcano_portal" {
				state.Values["expires_aut"] = json.RawMessage("6010")
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("Volcano clock was not saved")
	}

	if _, err := Restore(base); err == nil ||
		!strings.Contains(err.Error(), "Volcano portal") {
		t.Fatalf("forged Volcano deadline accepted: %v", err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	visit := g.Snapshot()
	removed := false

	for entityIndex := range visit.Entities {
		entity := &visit.Entities[entityIndex]
		kept := entity.Dynamic[:0]

		for _, state := range entity.Dynamic {
			if state.Schema == "character.volcano_visit" {
				removed = true
				continue
			}

			kept = append(kept, state)
		}

		entity.Dynamic = kept
	}

	if !removed {
		t.Fatal("Volcano visitor was not saved")
	}

	if _, err := Restore(visit); err == nil ||
		!strings.Contains(err.Error(), "Volcano floor") {
		t.Fatalf("missing Volcano visitor accepted: %v", err)
	}
}

// A saved outside gate opens one live Volcano floor. Any authored return
// arch goes back to the exact cell and retires the temporary floor.
func TestVolcanoEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88161)
	origin := placeVolcanoPortalForTest(t, g)
	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("unspent Volcano gate did not restore: %v", err)
	}

	g = restored

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]

	if floor == nil {
		t.Fatal("Volcano visit has no staged floor")
	}

	if floor.BranchID != "BRANCH_VOLCANO" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("Volcano entry lost its floor or gate: %+v", position)
	}

	restored, err = Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("Volcano visit did not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor = g.levels[position.LevelID]

	for y, row := range floor.Cells() {
		for x, feature := range row {
			if feature != terrain.ExitVolcano {
				continue
			}

			if err := floor.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			floorID := floor.ID

			if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
				t.Fatal(err)
			}

			position, _ = g.stores.Positions.Get(g.player)

			returnedToGate := position.LevelID == 1 &&
				position.X == origin.x && position.Y == origin.y

			if !returnedToGate || g.levels[floorID] != nil {
				t.Fatalf("Volcano did not return and retire: %+v", position)
			}

			if _, err := Restore(g.Snapshot()); err != nil {
				t.Fatalf("completed Volcano visit did not restore: %v", err)
			}

			return
		}
	}

	t.Fatal("Volcano destination has no return arch")
}
