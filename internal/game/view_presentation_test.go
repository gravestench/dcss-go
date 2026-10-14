package game

import "testing"

func TestViewPresentationIdentifiesEntitiesAndItemClass(t *testing.T) {
	g, err := NewScenario(7, testCatalog(t), "WPN_RAPIER", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	view := g.View()
	var player bool
	var rat bool
	var potion bool

	for _, entity := range view.Entities {
		switch entity.KindID {
		case "player":
			player = entity.Role == "player" && entity.Name == "Alice"

		case "MONS_RAT":
			rat = entity.Role == "monster" && entity.Name == "rat" && entity.Glyph == 'r'

		case "POT_CURING":
			potion = entity.Role == "item" && entity.Name != "" && entity.Glyph != 0
		}
	}

	if !player || !rat || !potion {
		t.Fatalf("entity presentation missing: %+v", view.Entities)
	}

	for _, item := range view.Inventory {
		if item.KindID == "WPN_RAPIER" && item.Class != "OBJ_WEAPONS" {
			t.Fatalf("rapier class: %+v", item)
		}
	}
}
