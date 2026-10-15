package game

import (
	"strings"
	"testing"
)

func grantTestSpell(t *testing.T, g *Game, spellID string) {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	store := g.scripts.Components()["character.spell"]

	if _, err := store.Set(entity, map[string]any{
		"owner":       g.player,
		"spell_id":    spellID,
		"known_slot":  int64(2),
		"letter_slot": int64(2),
	}); err != nil {
		t.Fatal(err)
	}

	progress, found := g.stores.Progression.Get(g.player)

	if !found {
		t.Fatal("player lacks progression")
	}

	progress.Level = 27

	if _, err := g.stores.Progression.Set(g.player, *progress); err != nil {
		t.Fatal(err)
	}

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player lacks magic")
	}

	magic.Current = 100
	magic.Max = 100

	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}
}

func TestFreezeUsesSourceRangeAndLuaEffect(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_ICE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	tooFar, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_FREEZE",
		DX:      2,
	})

	if err != nil {
		t.Fatal(err)
	}

	if tooFar.Spent != 0 {
		t.Fatalf("range-two Freeze spent %d aut", tooFar.Spent)
	}

	adjacent, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_FREEZE",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if adjacent.Spent == 0 {
		t.Fatal("adjacent Freeze did not spend time")
	}

	for _, event := range adjacent.Events {
		if strings.Contains(strings.ToLower(event.Text), "freeze") ||
			strings.Contains(strings.ToLower(event.Text), "miscast") {
			return
		}
	}

	t.Fatalf("Freeze had no Lua cast event: %+v", adjacent.Events)
}

func TestDirectTargetEffectsRunFromLua(t *testing.T) {
	for _, spellID := range []string{
		"SPELL_AIRSTRIKE",
		"SPELL_SMITING",
	} {
		t.Run(spellID, func(t *testing.T) {
			g, err := NewDungeonGame(
				43,
				"SP_HUMAN",
				"JOB_CONJURER",
				"",
				"Tester",
			)

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			grantTestSpell(t, g, spellID)
			position, found := g.stores.Positions.Get(g.player)

			if !found {
				t.Fatal("player lacks position")
			}

			level := g.levels[position.LevelID]
			dx, dy := 0, 0

			for y := -1; y <= 1 &&
				dx == 0 &&
				dy == 0; y++ {
				for x := -1; x <= 1; x++ {
					if (x != 0 || y != 0) &&
						level.Walkable(position.X+x, position.Y+y) {
						dx, dy = x, y
						break
					}
				}
			}

			if dx == 0 && dy == 0 {
				t.Fatal("no adjacent walkable target")
			}

			result, err := g.Step(Command{
				Kind:    CommandForceCast,
				SpellID: spellID,
				DX:      dx,
				DY:      dy,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent == 0 {
				t.Fatalf("%s did not spend time: %+v", spellID, result.Events)
			}
		})
	}
}

func TestInvokedEffectBypassesMemorisationAndMiscast(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	beforeAut := g.currentAut
	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player lacks magic")
	}

	beforeMP := magic.Current
	result, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
		"spell_id": "SPELL_SMITING",
		"power":    50,
		"dx":       1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result["invoked"] != true {
		t.Fatalf("Smiting invocation = %v", result)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	magic, _ = g.stores.Magic.Get(g.player)

	if g.currentAut != beforeAut || magic.Current != beforeMP {
		t.Fatal("invoked effect charged normal spell time or MP")
	}

	if _, err := g.scripts.Policy("magic.invoke_effect", map[string]any{
		"spell_id": "SPELL_GLACIATE",
		"power":    50,
	}); err == nil {
		t.Fatal("monster-only spell was accepted as player invocation")
	}
}
