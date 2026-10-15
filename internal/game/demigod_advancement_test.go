package game

import "testing"

func TestDemigodDivineAttributesChooseAtThreeAndSix(t *testing.T) {
	g, err := NewDungeonGame(
		1,
		"SP_DEMIGOD",
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Aster",
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	startingSave, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	startingSave.Close()
	progress, _ := g.stores.Progression.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)
	startingStrength := attributes.Strength

	progress.TotalXP = 100000

	training, _ := g.stores.SkillTraining.Get(g.player)

	training.AvailableXP = 10 * progress.TotalXP

	first, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if first.View.PendingStatLevel != 3 {
		t.Fatalf("Demigod first stat choice = %d, want XL3",
			first.View.PendingStatLevel)
	}

	second, err := g.ChooseStat("str")

	if err != nil {
		t.Fatal(err)
	}

	if attributes.Strength != startingStrength+4 ||
		second.View.PendingStatLevel != 6 {
		t.Fatalf("Demigod XL3 result = %+v, strength %d",
			second.View, attributes.Strength)
	}

	third, err := g.ChooseStat("str")

	if err != nil {
		t.Fatal(err)
	}

	if attributes.Strength != startingStrength+8 ||
		third.View.PendingStatLevel != 9 {
		t.Fatalf("Demigod XL6 result = %+v, strength %d",
			third.View, attributes.Strength)
	}

	clock, _ := g.stores.PlayerTurn.Get(g.player)

	if clock.NextAut <= int64(g.currentAut) {
		t.Fatalf("next stat choice lost the pending turn: aut %d, next %d",
			g.currentAut, clock.NextAut)
	}

	if _, err := g.scripts.Policy("save.validate_player", nil); err != nil {
		t.Fatalf("Demigod stat gains fail player save validation: %v", err)
	}
}
