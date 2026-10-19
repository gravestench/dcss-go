package game

import (
	"testing"

	"crawl/internal/ecs"
)

// A Chaos-created shifter is still the same roster actor after it takes a
// borrowed body. Its permanent variant and original identity survive restore.
func TestMonsterShapeshifterRestoresAndActs(t *testing.T) {
	g := newStepGame(t)
	monster := ratID(t, g)

	if _, err := g.stores.Actors.Set(monster, ecs.Actor{
		KindID: "MONS_SHAPESHIFTER",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.monster_polymorph"].Set(
		monster,
		map[string]any{
			"original_kind_id": "MONS_RAT",
		},
	); err != nil {
		t.Fatal(err)
	}

	shapes := g.scripts.Components()["combat.monster_shapeshifter"]

	if _, err := shapes.Set(monster, map[string]any{
		"variant_id":       "MONS_SHAPESHIFTER",
		"original_kind_id": "MONS_RAT",
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["combat.monster_shapeshifter"].Has(monster) {
		t.Fatal("shapeshifter identity lost on restore")
	}

	if _, err := loaded.runAction(monster, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	actor, _ := loaded.stores.Actors.Get(monster)

	if actor.KindID == "MONS_SHAPESHIFTER" {
		t.Fatal("restored base shifter did not take a borrowed body")
	}

	if !loaded.scripts.Components()["combat.monster_shapeshifter"].Has(monster) {
		t.Fatal("form change removed permanent shifter identity")
	}
}

// A malformed saved variant must not silently resume with the ordinary rate.
func TestMonsterShapeshifterRejectsInvalidVariant(t *testing.T) {
	g := newStepGame(t)
	monster := ratID(t, g)

	if _, err := g.scripts.Components()["combat.monster_shapeshifter"].Set(
		monster,
		map[string]any{
			"variant_id":       "MONS_RAT",
			"original_kind_id": "MONS_RAT",
		},
	); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if loaded != nil {
		loaded.Close()
	}

	if err == nil {
		t.Fatal("accepted a saved shape state with an invalid variant")
	}
}
