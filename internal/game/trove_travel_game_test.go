package game

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Install a source-shaped paid gate at the player cell. This fixture keeps
// travel independent of the rare D:10 entrance selection while exercising
// the production confirmation, staging, and return transaction.
func placeTrovePortalForTest(t *testing.T, g *Game) point {
	t.Helper()

	site := placePortalForTest(t, g, terrain.EnterTrove)
	position, _ := g.stores.Positions.Get(g.player)
	level := g.levels[position.LevelID]
	const sourceID = "enter_trove_1"
	const identity = "trove:toll"
	const price = "no_piety||0|0|||0"

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindMarker,
		SourceID: sourceID,
		Identity: identity,
		X:        site.x,
		Y:        site.y,
		Arguments: []vault.Argument{
			{
				Name:   "glyph",
				Kind:   vault.ValueString,
				String: "O",
			},
			{
				Name:   "price",
				Kind:   vault.ValueString,
				String: price,
			},
		},
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

	store := g.scripts.Components()["world.trove_portal"]

	if store == nil {
		t.Fatal("Trove ECS gate schema is missing")
	}

	if _, err := store.Set(entity, map[string]any{
		"level_id":          int64(level.ID),
		"x":                 int64(site.x),
		"y":                 int64(site.y),
		"vault_id":          sourceID,
		"record_index":      int64(len(level.vaultRecords)),
		"price_kind":        "no_piety",
		"item_id":           "",
		"quantity":          int64(0),
		"minimum_plus":      int64(0),
		"ego_id":            "",
		"artefact_name":     "",
		"source_rune_index": int64(0),
		"price_witness":     price,
		"spent":             false,
		"closure_reason":    "",
		"receipt_kind":      "",
		"receipt_item_id":   "",
		"receipt_quantity":  int64(0),
		"destination_id":    "",
	}); err != nil {
		t.Fatal(err)
	}

	return site
}

// Restore must join the source marker's canonical price to exactly one
// Akara gate. A changed component or missing owner is a forged save.
func TestTroveRejectsForgedPriceAndMissingGate(t *testing.T) {
	g := newGeneratedTestGame(t, 88164)
	placeTrovePortalForTest(t, g)
	base := g.Snapshot()
	changed := false

	for entityIndex := range base.Entities {
		for stateIndex := range base.Entities[entityIndex].Dynamic {
			state := &base.Entities[entityIndex].Dynamic[stateIndex]

			if state.Schema == "world.trove_portal" {
				state.Values["price_witness"] =
					json.RawMessage(`"item|SCR_ACQUIREMENT|2|0|||0"`)
				changed = true
			}
		}
	}

	if !changed {
		t.Fatal("Trove gate was not saved")
	}

	if _, err := Restore(base); err == nil ||
		!strings.Contains(err.Error(), "Trove") {
		t.Fatalf("forged Trove price accepted: %v", err)
	}

	missing := g.Snapshot()
	kept := missing.Entities[:0]

	for _, entity := range missing.Entities {
		gate := false

		for _, state := range entity.Dynamic {
			gate = gate || state.Schema == "world.trove_portal"
		}

		if !gate {
			kept = append(kept, entity)
		}
	}

	missing.Entities = kept

	if _, err := Restore(missing); err == nil ||
		!strings.Contains(err.Error(), "Trove") {
		t.Fatalf("missing Trove gate accepted: %v", err)
	}
}

// An accepted confirmation enters an authored reward floor, then its
// return arch takes the player to the exact outside cell and retires it.
func TestTroveEntrySaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 88164)
	origin := placeTrovePortalForTest(t, g)
	first, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if first.Confirmation == "" || first.ConfirmationTarget == "" ||
		first.Spent != 0 {
		t.Fatalf("Trove confirmation = %q, target = %q, spent = %d, events = %+v",
			first.Confirmation, first.ConfirmationTarget,
			first.Spent, first.Events)
	}

	confirmed := Command{
		Kind:     CommandDownstairs,
		Forced:   true,
		TargetID: first.ConfirmationTarget,
	}

	if _, err := g.Step(confirmed); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	floor := g.levels[position.LevelID]

	if floor == nil || floor.BranchID != "BRANCH_TROVE" ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.ExpiredPortal {
		t.Fatalf("Trove entry lost its floor or spent gate: %+v", position)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("active Trove visit did not restore: %v", err)
	}

	g = restored
	position, _ = g.stores.Positions.Get(g.player)
	floor = g.levels[position.LevelID]

	for y, row := range floor.Cells() {
		for x, cell := range row {
			if cell != terrain.ExitTrove {
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

			if position.LevelID != 1 || position.X != origin.x ||
				position.Y != origin.y || g.levels[floorID] != nil {
				t.Fatalf("Trove return missed outside gate: %+v", position)
			}

			if _, err := Restore(g.Snapshot()); err != nil {
				t.Fatalf("completed Trove visit did not restore: %v", err)
			}

			return
		}
	}

	t.Fatal("Trove destination has no return arch")
}

// A confirmation is tied to its original ECS gate. Replaying an old target
// must not debit a new gate or spend an action after the player moves.
func TestTroveStaleConfirmationDoesNotEnter(t *testing.T) {
	g := newGeneratedTestGame(t, 88164)
	origin := placeTrovePortalForTest(t, g)
	inspection, err := g.Step(Command{Kind: CommandInspect})
	showsPrice := false

	for _, event := range inspection.Events {
		showsPrice = showsPrice || strings.Contains(event.Text, "all favour")
	}

	if err != nil || inspection.Spent != 0 ||
		!showsPrice {
		t.Fatalf("Trove inspection hid the saved price: %+v, %v",
			inspection.Events, err)
	}

	first, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || first.ConfirmationTarget == "" {
		t.Fatalf("Trove did not offer a gate target: %+v, %v",
			first, err)
	}

	stale := Command{
		Kind:     CommandDownstairs,
		Forced:   true,
		TargetID: first.ConfirmationTarget + "-stale",
	}
	result, err := g.Step(stale)

	if err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if result.Spent != 0 || position.LevelID != 1 ||
		position.X != origin.x || position.Y != origin.y ||
		g.levels[1].terrain[origin.y][origin.x] != terrain.EnterTrove {
		t.Fatalf("stale Trove target changed the gate: %+v", position)
	}
}

// A paid Trove save has three witnesses: the outside receipt, the visitor,
// and the selected floor. Altering one must fail before play resumes.
func TestTroveRejectsForgedPaidVisit(t *testing.T) {
	g := newGeneratedTestGame(t, 88164)
	placeTrovePortalForTest(t, g)
	first, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:     CommandDownstairs,
		Forced:   true,
		TargetID: first.ConfirmationTarget,
	}); err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		name   string
		schema string
		field  string
		value  json.RawMessage
	}{
		{
			name:   "missing receipt",
			schema: "world.trove_portal",
			field:  "receipt_kind",
			value:  json.RawMessage(`""`),
		},
		{
			name:   "impossible piety loss",
			schema: "world.trove_portal",
			field:  "receipt_quantity",
			value:  json.RawMessage(`100000`),
		},
		{
			name:   "moved return site",
			schema: "character.trove_visit",
			field:  "origin_x",
			value:  json.RawMessage(`0`),
		},
		{
			name:   "changed selected room",
			schema: "character.trove_visit",
			field:  "vault_id",
			value:  json.RawMessage(`"not_a_trove_room"`),
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			state := g.Snapshot()
			changed := false

			for entityIndex := range state.Entities {
				for stateIndex := range state.Entities[entityIndex].Dynamic {
					component := &state.Entities[entityIndex].Dynamic[stateIndex]

					if component.Schema == tc.schema {
						component.Values[tc.field] = tc.value
						changed = true
					}
				}
			}

			if !changed {
				t.Fatalf("saved %s component was absent", tc.schema)
			}

			if _, err := Restore(state); err == nil ||
				!strings.Contains(err.Error(), "Trove") {
				t.Fatalf("forged paid Trove state restored: %v", err)
			}
		})
	}
}
