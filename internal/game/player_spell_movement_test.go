package game

import (
	"testing"

	"dcrawl-go/internal/character"
)

func TestBlinkMovesPlayerAndRejectsCooldown(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_BLINK")
	attributes, _ := g.stores.Attributes.Get(g.player)

	attributes.Intelligence = 100

	skills, _ := g.stores.Skills.Get(g.player)

	skills.Entries = append(skills.Entries, character.Skill{
		ID:    "SK_TRANSLOCATIONS",
		Level: 27,
	})

	if _, err := g.stores.Skills.Set(g.player, *skills); err != nil {
		t.Fatal(err)
	}

	before, _ := g.stores.Positions.Get(g.player)
	beforeX, beforeY := before.X, before.Y

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BLINK",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Blink spent no time: %+v", result.Events)
	}

	after, _ := g.stores.Positions.Get(g.player)

	if after.X == beforeX && after.Y == beforeY {
		t.Fatalf("Blink left player in place: %+v", result.Events)
	}

	status := testPlayerStatus()

	status["blink_cooldown_aut"] = int64(30)

	if _, err := g.scripts.Components()["magic.player_status"].Set(g.player, status); err != nil {
		t.Fatal(err)
	}

	cast, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_BLINK",
	})

	if err != nil {
		t.Fatal(err)
	}

	if cast.Spent != 0 {
		t.Fatalf("cooling Blink spent %d aut", cast.Spent)
	}
}
