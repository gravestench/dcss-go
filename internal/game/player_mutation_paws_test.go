package game

import "testing"

func sleepingRatDamage(t *testing.T, withPaws bool) int {
	t.Helper()

	g, err := NewScenario(1, "WPN_UNARMED", "Paws")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 100
	health.Max = 100

	if _, err := g.scripts.Components()["magic.monster_stasis"].Set(
		rat,
		map[string]any{
			"hibernating": true,
		},
	); err != nil {
		t.Fatal(err)
	}

	if withPaws {
		addPlayerMutation(t, g, "MUT_PAWS")
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("sleeping rat attack spent no time")
	}

	after, _ := g.stores.Health.Get(rat)

	return 100 - after.Current
}

func TestPawsImproveUnarmedStabAgainstSleepingMonster(t *testing.T) {
	ordinary := sleepingRatDamage(t, false)
	withPaws := sleepingRatDamage(t, true)

	if withPaws <= ordinary {
		t.Fatalf("sleeping stab damage: paws %d, ordinary %d",
			withPaws, ordinary)
	}
}
