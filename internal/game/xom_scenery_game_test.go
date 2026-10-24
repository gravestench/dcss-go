package game

import (
	"testing"

	"crawl/internal/terrain"
)

// Xom's scenery altar is terrain, so it must remain usable after the floor
// is saved and restored without a DES source-feature record.
func TestXomSceneryAltarPrayerSurvivesSave(t *testing.T) {
	game, rules := newReligionRecordsGame(t, 923)

	defer game.Close()

	position, found := game.stores.Positions.Get(game.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := game.levels[position.LevelID]
	placed := false

	for y, row := range level.terrain {
		for x, feature := range row {
			_, occupied := level.ActorAt(x, y)

			if feature != terrain.Floor || occupied {
				continue
			}

			if err := level.MoveActor(game.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.SetCell(x, y, terrain.XomAltar); err != nil {
				t.Fatal(err)
			}

			placed = true
			break
		}

		if placed {
			break
		}
	}

	if !placed {
		t.Fatal("generated floor has no free floor for Xom altar")
	}

	offer, err := game.Step(Command{Kind: CommandPray})

	if err != nil {
		t.Fatal(err)
	}

	if offer.ConfirmationTarget != "GOD_XOM" || offer.Spent != 0 {
		t.Fatalf("Xom altar offer: target=%q spent=%d",
			offer.ConfirmationTarget, offer.Spent)
	}

	restored, err := RestoreWithRules(game.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	offer, err = restored.Step(Command{Kind: CommandPray})

	if err != nil {
		t.Fatal(err)
	}

	if offer.ConfirmationTarget != "GOD_XOM" || offer.Spent != 0 {
		t.Fatalf("restored Xom altar offer: target=%q spent=%d",
			offer.ConfirmationTarget, offer.Spent)
	}
}
