package game

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// The saved closure reason distinguishes entry from natural expiry even
// though both leave the same expired arch feature on the outside grid.
func iceCaveClosureReason(t *testing.T, g *Game) string {
	t.Helper()

	for _, entity := range g.Snapshot().Entities {
		for _, part := range entity.Dynamic {
			if part.Schema != "world.ice_cave_portal" {
				continue
			}

			var reason string

			if err := json.Unmarshal(part.Values["closure_reason"], &reason); err != nil {
				t.Fatal(err)
			}

			return reason
		}
	}

	t.Fatal("Ice Cave portal has no saved ECS clock")

	return ""
}

// A source-position marker and its ECS gate save the same clock and hard
// choice. This helper places their real types on a generated Dungeon floor.
func placeIceCavePortalForTest(t *testing.T, g *Game, hard bool) point {
	t.Helper()

	position, _ := g.stores.Positions.Get(g.player)

	if hard && g.levels[position.LevelID].LocalDepth < 14 {
		descendGeneratedTo(t, g, 14)
	}

	site := placePortalForTest(t, g, terrain.EnterIceCave)
	position, _ = g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	choice := "false"

	if hard {
		choice = "true"
	}

	identity := `lua:timed_marker { low = 600, high = 600, hard = ` +
		choice + `, single_timed = true, floor = "expired_portal" }`
	const sourceID = "portal_ice_cave_entry_pillars_1"

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

	store := g.scripts.Components()["world.ice_cave_portal"]

	if store == nil {
		t.Fatal("Ice Cave ECS clock schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":        int64(level.ID),
		"x":               int64(site.x),
		"y":               int64(site.y),
		"vault_id":        sourceID,
		"record_index":    int64(len(level.vaultRecords)),
		"hard":            hard,
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

// Enter, save, restore, and return through the production staged transaction.
// The exact source cell remains the only valid return destination.
func TestIceCaveEntrySaveAndExit(t *testing.T) {
	for _, hard := range []bool{false, true} {
		name := "easy"

		if hard {
			name = "hard"
		}

		t.Run(name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88161)
			origin := placeIceCavePortalForTest(t, g, hard)
			originLevelID := 1

			if hard {
				originLevelID = 14
			}

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("unspent Ice Cave gate did not restore: %v", err)
			}

			g = restored

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			position, _ := g.stores.Positions.Get(g.player)
			floor := g.levels[position.LevelID]

			if floor == nil ||
				floor.BranchID != "BRANCH_ICE_CAVE" ||
				g.levels[originLevelID].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
				t.Fatalf("Ice Cave entry lost its floor or gate: %+v", position)
			}

			if reason := iceCaveClosureReason(t, g); reason != "entry" {
				t.Fatalf("entered gate closure reason = %q", reason)
			}

			restored, err = Restore(g.Snapshot())

			if err != nil {
				t.Fatalf("Ice Cave visit did not restore: %v", err)
			}

			g = restored
			position, _ = g.stores.Positions.Get(g.player)
			floor = g.levels[position.LevelID]

			for y, row := range floor.Cells() {
				for x, feature := range row {
					if feature != terrain.ExitIceCave {
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

					if position.LevelID != originLevelID ||
						position.X != origin.x ||
						position.Y != origin.y ||
						g.levels[floorID] != nil {
						t.Fatalf("Ice Cave did not return and retire: %+v", position)
					}

					if _, err := Restore(g.Snapshot()); err != nil {
						t.Fatalf("completed Ice Cave visit did not restore: %v", err)
					}

					return
				}
			}

			t.Fatal("Ice Cave destination has no return arch")
		})
	}
}

// Player action time keeps advancing while the original floor is inactive.
func TestIceCaveGateExpiresOnInactiveFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 88162)
	origin := placeIceCavePortalForTest(t, g, false)
	descendGeneratedTo(t, g, 2)
	g.currentAut = 5990

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatal("inactive Ice Cave gate survived its deadline")
	}

	if reason := iceCaveClosureReason(t, g); reason != "expiry" {
		t.Fatalf("expired gate closure reason = %q", reason)
	}
}

// An accepted step through the gate at its last valid time must complete
// before the action's expiry event can mutate that gate.
func TestIceCaveGateAllowsTravelAtDeadline(t *testing.T) {
	g := newGeneratedTestGame(t, 88163)
	placeIceCavePortalForTest(t, g, true)
	g.currentAut += 5990

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.levels[position.LevelID] == nil ||
		g.levels[position.LevelID].BranchID != "BRANCH_ICE_CAVE" {
		t.Fatalf("accepted Ice Cave entry lost deadline travel: %+v", position)
	}
}

// The source marker independently records hard choice and exact duration;
// editing either ECS field must fail restore, even within a legal range.
func TestIceCaveRestoreRejectsForgedGate(t *testing.T) {
	for _, change := range []struct {
		name  string
		value json.RawMessage
	}{
		{
			name:  "hard",
			value: json.RawMessage(`true`),
		},

		{
			name:  "duration_turns",
			value: json.RawMessage(`601`),
		},

		{
			name:  "expires_aut",
			value: json.RawMessage(`6010`),
		},
	} {
		t.Run(change.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88167)
			placeIceCavePortalForTest(t, g, false)
			changed := g.Snapshot()

			for entityIndex := range changed.Entities {
				for partIndex := range changed.Entities[entityIndex].Dynamic {
					part := &changed.Entities[entityIndex].Dynamic[partIndex]

					if part.Schema == "world.ice_cave_portal" {
						part.Values[change.name] = change.value
					}
				}
			}

			if _, err := Restore(changed); err == nil ||
				!strings.Contains(strings.ToLower(err.Error()), "ice cave") {
				t.Fatalf("forged Ice Cave %s was accepted: %v",
					change.name, err)
			}
		})
	}
}

// An expired arch is legal only after its saved deadline. Changing the
// reason and cell together cannot make a live portal close early.
func TestIceCaveRestoreRejectsPrematureExpiry(t *testing.T) {
	g := newGeneratedTestGame(t, 88170)
	site := placeIceCavePortalForTest(t, g, false)
	changed := g.Snapshot()

	for levelIndex := range changed.Levels {
		if changed.Levels[levelIndex].ID == 1 {
			changed.Levels[levelIndex].Cells[site.y][site.x] =
				terrain.ExpiredPortal
		}
	}

	for entityIndex := range changed.Entities {
		for partIndex := range changed.Entities[entityIndex].Dynamic {
			part := &changed.Entities[entityIndex].Dynamic[partIndex]

			if part.Schema == "world.ice_cave_portal" {
				part.Values["spent"] = json.RawMessage(`true`)
				part.Values["closure_reason"] = json.RawMessage(`"expiry"`)
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(strings.ToLower(err.Error()), "ice cave") {
		t.Fatalf("premature Ice Cave expiry was accepted: %v", err)
	}
}

// Even two mutually consistent saved hard bits cannot override the
// entrance floor's source rule at D:14.
func TestIceCaveRestoreRejectsForgedOriginDifficulty(t *testing.T) {
	g := newGeneratedTestGame(t, 88171)
	placeIceCavePortalForTest(t, g, true)
	changed := g.Snapshot()

	for levelIndex := range changed.Levels {
		level := &changed.Levels[levelIndex]

		if level.ID != 14 {
			continue
		}

		for recordIndex := range level.VaultRecords {
			record := &level.VaultRecords[recordIndex]

			if record.SourceID == "portal_ice_cave_entry_pillars_1" {
				record.Identity = strings.Replace(record.Identity,
					"hard = true", "hard = false", 1)
			}
		}
	}

	for entityIndex := range changed.Entities {
		for partIndex := range changed.Entities[entityIndex].Dynamic {
			part := &changed.Entities[entityIndex].Dynamic[partIndex]

			if part.Schema == "world.ice_cave_portal" {
				part.Values["hard"] = json.RawMessage(`false`)
			}
		}
	}

	if _, err := Restore(changed); err == nil ||
		!strings.Contains(strings.ToLower(err.Error()), "ice cave") {
		t.Fatalf("D:14 Ice Cave gate changed to easy: %v", err)
	}
}

// The active visit must agree with its spent outside gate on both the
// source coordinate and difficulty, not merely on the floor ID.
func TestIceCaveRestoreRejectsForgedVisit(t *testing.T) {
	for _, change := range []struct {
		name  string
		value json.RawMessage
	}{
		{
			name:  "hard",
			value: json.RawMessage(`true`),
		},

		{
			name:  "origin_x",
			value: json.RawMessage(`1`),
		},
	} {
		t.Run(change.name, func(t *testing.T) {
			g := newGeneratedTestGame(t, 88168)
			placeIceCavePortalForTest(t, g, false)

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			changed := g.Snapshot()

			for entityIndex := range changed.Entities {
				for partIndex := range changed.Entities[entityIndex].Dynamic {
					part := &changed.Entities[entityIndex].Dynamic[partIndex]

					if part.Schema == "character.ice_cave_visit" {
						part.Values[change.name] = change.value
					}
				}
			}

			if _, err := Restore(changed); err == nil {
				t.Fatalf("forged Ice Cave visit %s was accepted", change.name)
			}
		})
	}
}

// An actor occupying the exact outside cell keeps the temporary cave
// active and makes return cost no action time or durable state mutation.
func TestIceCaveReturnWaitsForExactOutsideCell(t *testing.T) {
	g := newGeneratedTestGame(t, 88169)
	origin := placeIceCavePortalForTest(t, g, false)

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
		for x, feature := range row {
			if feature != terrain.ExitIceCave {
				continue
			}

			if err := floor.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			beforeState := g.Snapshot()
			before, err := json.Marshal(beforeState)

			if err != nil {
				t.Fatal(err)
			}

			result, err := g.Step(Command{Kind: CommandUpstairs})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 0 || g.levels[floor.ID] == nil {
				t.Fatalf("blocked Ice Cave return changed the visit: %+v", result)
			}

			afterState := g.Snapshot()

			afterState.Messages = beforeState.Messages

			after, err := json.Marshal(afterState)

			if err != nil {
				t.Fatal(err)
			}

			if !bytes.Equal(before, after) {
				t.Fatal("blocked Ice Cave return changed saved state")
			}

			return
		}
	}

	t.Fatal("Ice Cave destination has no return arch")
}
