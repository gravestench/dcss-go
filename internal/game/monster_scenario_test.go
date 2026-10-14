package game

import "testing"

func TestRatScenarioKeepsFourHPAndThreeDamage(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, ok := g.stores.Health.Get(rat)
	if !ok || health.Current != 4 || health.Max != 4 {
		t.Fatalf("rat health = %+v, found %v", health, ok)
	}
	combat, ok := g.stores.Combat.Get(rat)
	if !ok || combat.BaseDamage != 3 {
		t.Fatalf("rat damage = %+v, found %v", combat, ok)
	}
}
