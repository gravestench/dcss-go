package game

import "testing"

func TestSilenceAuraBlocksPlayerSpellWithoutSpendingTime(t *testing.T) {
	g := newZapGame(t)
	defer g.Close()

	grantSelfStatusSpell(t, g, "SPELL_SWIFTNESS")
	addPlayerMutation(t, g, "MUT_SILENCE_AURA")

	blocked, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SWIFTNESS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if blocked.Spent != 0 {
		t.Fatalf("Silence Aura spell attempt spent %d aut", blocked.Spent)
	}

	if !containsEvent(blocked.Events, "You cannot cast spells when silenced!") {
		t.Fatalf("Silence Aura gave no spell refusal: %+v", blocked.Events)
	}
}
