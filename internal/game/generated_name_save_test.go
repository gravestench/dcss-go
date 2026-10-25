package game

import (
	"strings"
	"testing"
)

// Jiyva's second name is rolled once for every character. A later faith
// change can display the saved name without consuming another random draw.
func TestJiyvaSecondNameSurvivesRestore(t *testing.T) {
	game, err := NewDungeonGame(
		614,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Name tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()
	store := game.scripts.Components()["character.jiyva_second_name"]
	name, found := store.Get(game.player)

	if !found {
		t.Fatal("new character has no saved Jiyva second name")
	}

	initial, err := name.Get("name")

	if err != nil {
		t.Fatal(err)
	}

	spelling := initial.(string)

	if len(spelling) < 4 ||
		len(spelling) > 8 ||
		!strings.HasPrefix(spelling, "J") {
		t.Fatalf("invalid initial Jiyva second name %q", spelling)
	}

	restored, err := Restore(game.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	record, found := restored.scripts.Components()["character.jiyva_second_name"].Get(restored.player)

	if !found {
		t.Fatal("restore lost the Jiyva second name")
	}

	replayed, err := record.Get("name")

	if err != nil ||
		replayed != spelling {
		t.Fatalf("restored Jiyva name = %v, %v", replayed, err)
	}

	if err := record.Set("name", "Invalid Name"); err != nil {
		t.Fatal(err)
	}

	invalid, err := Restore(restored.Snapshot())

	if invalid != nil {
		invalid.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "invalid saved Jiyva second name") {
		t.Fatalf("invalid Jiyva name passed restore: %v", err)
	}
}
