package game

import (
	"testing"

	"crawl/internal/ecs"
)

// A generated endoplasm has the source jelly genus. Prayer and monster
// scheduling must give it durable Jiyva allegiance through the real Lua
// system, ECS store, and Go save restore path.
func TestJiyvaConvertsGeneratedEndoplasmAndRestores(t *testing.T) {
	g, endoplasm := newEndoplasmGame(t, false)

	placePrayerAltar(t, g, "GOD_JIYVA")

	if _, err := g.Step(Command{Kind: CommandPray}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{
		Kind:     CommandPray,
		TargetID: "GOD_JIYVA",
		Forced:   true,
	}); err != nil {
		t.Fatal(err)
	}

	if worshipGod(t, g) != "GOD_JIYVA" {
		t.Fatal("prayer did not join Jiyva")
	}

	store := g.scripts.Components()["religion.jiyva_slime"]

	if !store.Has(endoplasm) {
		energy, _ := g.stores.MonsterEnergy.Get(endoplasm)

		energy.Points = 80

		if _, err := g.runAction(endoplasm,
			ecs.Intent{}, 10, "monster"); err != nil {
			t.Fatal(err)
		}
	}

	state, found := store.Get(endoplasm)

	if !found {
		t.Fatal("Jiyva did not convert the generated endoplasm")
	}

	attitude, err := state.Get("attitude")

	if err != nil {
		t.Fatal(err)
	}

	if attitude != "good_neutral" {
		t.Fatalf("converted endoplasm attitude = %v", attitude)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	saved := restored.scripts.Components()["religion.jiyva_slime"]
	loaded, found := saved.Get(endoplasm)

	if !found {
		t.Fatal("restored endoplasm lost Jiyva allegiance")
	}

	attitude, err = loaded.Get("attitude")

	if err != nil {
		t.Fatal(err)
	}

	if attitude != "good_neutral" {
		t.Fatalf("restored attitude = %v, want good_neutral", attitude)
	}
}
