package game

import "testing"

func TestRatScenarioKeepsFourHPAndCatalogedBite(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)
	health, ok := g.stores.Health.Get(rat)
	if !ok || health.Current != 4 || health.Max != 4 {
		t.Fatalf("rat health = %+v, found %v", health, ok)
	}
	combat, ok := g.stores.Combat.Get(rat)
	definition, err := g.catalog.Monster("MONS_RAT")
	if !ok || combat.ShieldBlocks != 0 || err != nil || definition.HD != 1 || definition.Attacks[0].Damage != 3 {
		t.Fatalf("rat combat/source = %+v/%+v, found %v, error %v", combat, definition, ok, err)
	}
}
