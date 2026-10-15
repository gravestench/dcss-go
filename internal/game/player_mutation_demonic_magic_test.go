package game

import "testing"

func TestDemonicMagicTriggersAfterSuccessfulPlayerSpell(t *testing.T) {
	g := newZapGame(t)
	grantSelfStatusSpell(t, g, "SPELL_SWIFTNESS")
	addPlayerMutation(t, g, "MUT_DEMONIC_MAGIC")

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SWIFTNESS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if !containsEvent(result.Events, "Malevolent energies surge around you.") {
		t.Fatalf("successful spell did not trigger Demonic Magic: %+v", result.Events)
	}
}
