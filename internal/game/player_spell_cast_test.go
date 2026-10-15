package game

import (
	"strings"
	"testing"
)

func TestUnknownPlayerCastCostsNoTime(t *testing.T) {
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

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_GLACIATE",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatalf("unknown spell spent %d aut", result.Spent)
	}
}

func TestTargetCancellationCostsNoTime(t *testing.T) {
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

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_MAGIC_DART",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatalf("cancelled cast spent %d aut", result.Spent)
	}
}

func TestMagicDartRunsThroughLuaSpellEffect(t *testing.T) {
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

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_MAGIC_DART",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Magic Dart did not spend time: %+v", result.Events)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "magic dart") {
			return
		}
	}

	t.Fatalf("Magic Dart had no Lua effect event: %+v", result.Events)
}

func TestMagicDartOrdinaryCastNeedsHostileInRange(t *testing.T) {
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

	for _, monster := range g.stores.MonsterEnergy.Entities() {
		health, found := g.stores.Health.Get(monster)

		if found {
			health.Current = 0
		}
	}

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_MAGIC_DART",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatalf("cast without hostiles spent %d aut", result.Spent)
	}
}
