package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

func TestApportationPullsVisibleGroundItem(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_APPORTATION")
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

	item := potionID(t, g)

	if _, err := g.stores.Positions.Set(item, ecs.Position{
		LevelID: 1,
		X:       5,
		Y:       1,
	}); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_APPORTATION",
		DX:      4,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatalf("Apportation spent no time: %+v", result.Events)
	}

	position, found := g.stores.Positions.Get(item)

	if !found ||
		position.X != 1 ||
		position.Y != 1 {
		t.Fatalf("Apportation item position = %+v, found %v", position, found)
	}
}

func TestApportationRejectsEmptyCellWithoutTime(t *testing.T) {
	g := newStepGame(t)
	grantTestSpell(t, g, "SPELL_APPORTATION")
	result, err := g.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_APPORTATION",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("empty Apportation spent %d aut", result.Spent)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "don't see anything to apport") {
			return
		}
	}

	t.Fatalf("empty Apportation gave wrong rejection: %+v", result.Events)
}
