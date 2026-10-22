package game

import (
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// Put one catalogued altar under the player so command tests use the real
// level record, grid cell, Lua command bridge, and save validator.
func placePrayerAltar(t *testing.T, g *Game, godID string) {
	t.Helper()

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("praying player has no position")
	}

	level := g.levels[position.LevelID]
	located := false

	for y, row := range level.terrain {
		for x, feature := range row {
			_, occupied := level.ActorAt(x, y)

			if feature != terrain.Floor || occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			position, _ = g.stores.Positions.Get(g.player)
			located = true
			break
		}

		if located {
			break
		}
	}

	if !located {
		t.Fatal("generated floor has no empty floor for altar")
	}

	sourceID := level.VaultID()

	if sourceID == "" {
		t.Fatal("generated level has no catalogued source")
	}

	if err := level.SetCell(position.X, position.Y, terrain.Altar); err != nil {
		t.Fatal(err)
	}

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindSourceFeature,
		SourceID: sourceID,
		Identity: string(terrain.Altar),
		X:        position.X,
		Y:        position.Y,
		Arguments: []vault.Argument{
			{
				Name:   "god_id",
				Kind:   vault.ValueString,
				String: godID,
			},
		},
	}); err != nil {
		t.Fatal(err)
	}
}

// Inspect the authoritative ECS field instead of asserting a label that the
// terminal might have cached from before the conversion.
func worshipGod(t *testing.T, g *Game) string {
	t.Helper()

	store := g.scripts.Components()["religion.worship"]
	state, found := store.Get(g.player)

	if !found {
		t.Fatal("player has no worship state")
	}

	value, err := state.Get("god_id")

	if err != nil {
		t.Fatal(err)
	}

	return value.(string)
}

// Confirmation is a free command; acceptance spends an action and saves the
// new patron. A refused or repeated prayer cannot charge another turn.
func TestPrayerConversionUsesSavedAltarAndTurn(t *testing.T) {
	g, rules := newReligionRecordsGame(t, 451)

	defer g.Close()

	placePrayerAltar(t, g, "GOD_ZIN")
	before := g.View().CurrentAut

	offer, err := g.Step(Command{Kind: CommandPray})

	if err != nil {
		t.Fatal(err)
	}

	if offer.Spent != 0 ||
		offer.Confirmation == "" ||
		offer.ConfirmationTarget != "GOD_ZIN" {
		t.Fatalf("prayer offer: spent=%d prompt=%q target=%q events=%+v",
			offer.Spent, offer.Confirmation, offer.ConfirmationTarget, offer.Events)
	}

	if worshipGod(t, g) != "GOD_NO_GOD" ||
		g.View().CurrentAut != before {
		t.Fatal("unaccepted prayer changed worship or time")
	}

	accepted, err := g.Step(Command{
		Kind:     CommandPray,
		TargetID: "GOD_ZIN",
		Forced:   true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if accepted.Spent == 0 || worshipGod(t, g) != "GOD_ZIN" {
		t.Fatalf("confirmed prayer: spent=%d events=%+v god=%s",
			accepted.Spent, accepted.Events, worshipGod(t, g))
	}

	own, err := g.Step(Command{Kind: CommandPray})

	if err != nil {
		t.Fatal(err)
	}

	if own.Spent != 0 || own.Confirmation != "" {
		t.Fatalf("own altar prayer: spent=%d prompt=%q events=%+v",
			own.Spent, own.Confirmation, own.Events)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if worshipGod(t, restored) != "GOD_ZIN" {
		t.Fatal("restored prayer lost worship")
	}
}

// The unknown god stays unknown during confirmation, then the accepted
// command binds one concrete ID to both worship and the saved altar record.
func TestEcumenicalPrayerIdentifiesSavedAltar(t *testing.T) {
	g, rules := newReligionRecordsGame(t, 453)

	defer g.Close()

	placePrayerAltar(t, g, "GOD_ECUMENICAL")

	offer, err := g.Step(Command{Kind: CommandPray})

	if err != nil {
		t.Fatal(err)
	}

	if offer.ConfirmationTarget != "GOD_ECUMENICAL" ||
		worshipGod(t, g) != "GOD_NO_GOD" {
		t.Fatalf("unknown altar offer: target=%q events=%+v",
			offer.ConfirmationTarget, offer.Events)
	}

	accepted, err := g.Step(Command{
		Kind:     CommandPray,
		TargetID: offer.ConfirmationTarget,
		Forced:   true,
	})

	if err != nil {
		t.Fatal(err)
	}

	godID := worshipGod(t, g)

	if accepted.Spent == 0 ||
		godID == "GOD_NO_GOD" ||
		godID == "GOD_ECUMENICAL" {
		t.Fatalf("unknown altar result: spent=%d events=%+v god=%s",
			accepted.Spent, accepted.Events, godID)
	}

	position, _ := g.stores.Positions.Get(g.player)
	records := g.levels[position.LevelID].VaultRecords()
	altar := records[len(records)-1]

	if altar.Arguments[0].String != godID {
		t.Fatalf("saved altar %s differs from worship %s",
			altar.Arguments[0].String, godID)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if worshipGod(t, restored) != godID {
		t.Fatal("restored unknown altar conversion changed god")
	}
}
