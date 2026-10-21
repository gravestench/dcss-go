package game

import "testing"

// The live entity view must carry the catalog's animated colour marker to
// the terminal without changing the monster's saved actor or game RNG.
func TestMonsterViewKeepsCatalogRandomColour(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	rat := ratID(t, g)
	actor, found := g.stores.Actors.Get(rat)

	if !found {
		t.Fatal("test monster has no actor")
	}

	actor.KindID = "MONS_KILLER_KLOWN"

	view := g.View()

	for _, entity := range view.Entities {
		if entity.ID != uint64(rat) {
			continue
		}

		if entity.ColorID != "ETC_RANDOM" || !entity.AnimatedColor {
			t.Fatalf("animated monster colour was lost: %+v", entity)
		}

		return
	}

	t.Fatal("test monster is absent from the visible entity view")
}
