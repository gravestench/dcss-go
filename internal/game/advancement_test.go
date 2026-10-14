package game

import "testing"

func TestStatChoiceInterruptsMonsterPhase(t *testing.T) {
	g := newStepGame(t)
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 2
	progress.TotalXP = 29

	monsterEnergy := make(map[uint64]int)

	for _, entity := range g.stores.AI.Entities() {
		energy, _ := g.stores.MonsterEnergy.Get(entity)

		monsterEnergy[uint64(entity)] = energy.Points
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.PendingStatLevel != 3 || g.currentAut != 0 {
		t.Fatalf("stat prompt did not interrupt turn: %+v", result)
	}

	for _, entity := range g.stores.AI.Entities() {
		energy, _ := g.stores.MonsterEnergy.Get(entity)

		if energy.Points != monsterEnergy[uint64(entity)] {
			t.Fatalf("monster %d acted before stat choice", entity)
		}
	}

	chosen, err := g.ChooseStat("dex")

	if err != nil {
		t.Fatal(err)
	}

	if chosen.View.PendingStatLevel != 0 ||
		chosen.View.ExperienceLevel != 3 ||
		g.currentAut != 10 {
		t.Fatalf("stat choice did not finish turn: %+v", chosen)
	}
}
