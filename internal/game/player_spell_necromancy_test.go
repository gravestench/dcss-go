package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/character"
)

func TestSublimationRejectsFullMagicWithoutTime(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_SUBLIMATION_OF_BLOOD")
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUBLIMATION_OF_BLOOD",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("full-MP Sublimation spent %d aut", result.Spent)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "reserves of magic are already full") {
			return
		}
	}

	t.Fatalf("full-MP Sublimation gave wrong rejection: %+v", result.Events)
}

func TestSublimationTradesHealthForMagic(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_SUBLIMATION_OF_BLOOD")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	skills, _ := g.stores.Skills.Get(g.player)

	skills.Entries = append(skills.Entries, character.Skill{
		ID:    "SK_NECROMANCY",
		Level: 27,
	})

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Current = 3

	beforeHP, _ := g.stores.Health.Get(g.player)
	previousHP := beforeHP.Current
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_SUBLIMATION_OF_BLOOD",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Sublimation spent no time: %+v", result.Events)
	}

	afterHP, _ := g.stores.Health.Get(g.player)
	afterMagic, _ := g.stores.Magic.Get(g.player)

	if afterHP.Current >= previousHP || afterMagic.Current <= 1 {
		t.Fatalf("Sublimation HP/MP = %d/%d: %+v",
			afterHP.Current, afterMagic.Current, result.Events)
	}
}

func TestRevivificationRejectsFullHealthWithoutTime(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_BORGNJORS_REVIVIFICATION")
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BORGNJORS_REVIVIFICATION",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("full-HP Revivification spent %d aut", result.Spent)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "cannot be healed further") {
			return
		}
	}

	t.Fatalf("full-HP Revivification gave wrong rejection: %+v", result.Events)
}

func TestRevivificationHealsWithPermanentLossAndParalysis(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_BORGNJORS_REVIVIFICATION")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	skills, _ := g.stores.Skills.Get(g.player)

	skills.Entries = append(skills.Entries, character.Skill{
		ID:    "SK_NECROMANCY",
		Level: 27,
	})

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 166
	health.Current = 3

	if _, err := g.stores.Health.Set(g.player, *health); err != nil {
		t.Fatal(err)
	}

	status := testPlayerStatus()

	status["death_door_aut"] = int64(100)
	status["death_door_hp"] = int64(3)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, status); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BORGNJORS_REVIVIFICATION",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Revivification spent no time: %+v", result.Events)
	}

	after, _ := g.stores.Health.Get(g.player)

	if after.Current != after.Max || after.Max >= 166 {
		t.Fatalf("Revivification health = %d/%d", after.Current, after.Max)
	}

	if luaIntField(t, g, "magic.permanent_hp_loss", "amount") <= 0 {
		t.Fatal("Revivification did not save permanent HP loss")
	}

	if luaIntField(t, g, "magic.player_status", "death_door_aut") != 0 ||
		luaIntField(t, g, "magic.player_paralysis", "remaining_aut") <= 0 {
		t.Fatal("Revivification failed to abort Death's Door with paralysis")
	}

	position, _ := g.stores.Positions.Get(g.player)
	beforeX, beforeY := position.X, position.Y
	wait, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if wait.Spent == 0 ||
		position.X != beforeX ||
		position.Y != beforeY {
		t.Fatal("paralysed player moved or spent no time")
	}
}
