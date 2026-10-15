package game

import "testing"

func TestUnravellingBlastDamagesAndMalmutatesCaster(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_VIOLENT_UNRAVELLING")

	rat := seededPlainBiteMonster(t, g, "MONS_RAT", 1)
	dx, dy := placePlayerBesideMonster(t, g, rat)

	rejected, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_VIOLENT_UNRAVELLING",
		DX:      dx,
		DY:      dy,
	})

	if err != nil {
		t.Fatal(err)
	}

	if rejected.Spent != 0 {
		t.Fatalf("unenchanted target cost %d aut", rejected.Spent)
	}

	enchant := g.scripts.Components()["magic.monster_enchant"]

	if _, err := enchant.Set(rat, map[string]any{
		"blind_aut":     int64(100),
		"corrosion_aut": int64(0),
	}); err != nil {
		t.Fatal(err)
	}

	before, _ := g.stores.Health.Get(g.player)
	buffered := *before

	buffered.Max = 200
	buffered.Current = 200

	if _, err := g.stores.Health.Set(g.player, buffered); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_VIOLENT_UNRAVELLING",
		DX:      dx,
		DY:      dy,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || result.Confirmation == "" {
		t.Fatalf("adjacent Unravelling did not ask before hitting caster: %+v",
			result)
	}

	result, err = g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_VIOLENT_UNRAVELLING",
		DX:      dx,
		DY:      dy,
		Forced:  true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!containsEvent(result.Events, "Unravelled magic bursts outward!") {
		t.Fatalf("unravelling did not resolve: %+v", result)
	}

	after, _ := g.stores.Health.Get(g.player)

	if after.Current >= buffered.Current {
		t.Fatalf("caster blast dealt no damage: %d -> %d", buffered.Current, after.Current)
	}

	mutation := playerMutationRecords(t, g)

	if len(mutation) == 0 {
		t.Fatal("caster blast produced no player mutation")
	}
}

func TestUnravellingEmptyAimCanBeConfirmedAndFizzles(t *testing.T) {
	g := newZapGame(t)
	grantZapForTest(t, g, "SPELL_VIOLENT_UNRAVELLING")

	command := Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_VIOLENT_UNRAVELLING",
		DX:      1,
	}

	before := g.View().CurrentAut
	prompt, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if prompt.Spent != 0 ||
		prompt.Confirmation == "" ||
		g.View().CurrentAut != before {
		t.Fatalf("empty aim spent time without confirmation: %+v", prompt)
	}

	command.Forced = true

	result, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 || !containsEvent(result.Events,
		"The spell fizzles.") {
		t.Fatalf("confirmed empty aim did not fizzle: %+v", result)
	}
}
