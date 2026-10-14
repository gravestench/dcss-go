package game

import (
	"testing"

	"github.com/gravestench/akara"
)

func potionID(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	for _, id := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(id)

		if item.KindID == "POT_CURING" {
			return id
		}
	}

	t.Fatal("potion missing")

	return 0
}

func TestPickupTransfersLocation(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 4, 2); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil {
		t.Fatal(err)
	}

	item := potionID(t, g)
	carrier, carried := g.stores.CarriedBy.Get(item)

	if result.Spent != 10 ||
		g.stores.Positions.Has(item) ||
		!carried ||
		carrier.Holder != g.player ||
		len(result.View.Inventory) != 5 || result.View.Inventory[4].KindID != "POT_CURING" {
		t.Fatalf(
			"pickup = %+v, located=%v, carried=%+v, inventory=%+v",
			result,
			g.stores.Positions.Has(item),
			carrier,
			result.View.Inventory,
		)
	}
}

func TestPickupEmptyCellIsFree(t *testing.T) {
	g := newStepGame(t)
	result, err := g.Step(Command{Kind: CommandPickup})

	if err != nil || result.Spent != 0 {
		t.Fatalf("empty pickup = %+v, %v", result, err)
	}
}

func TestViewIsCopied(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 4, 2); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	view := g.View()

	view.Cells[0].Glyph = '?'
	view.Entities[0].X = 99
	view.Messages[0] = "changed"
	view.Inventory[0].Name = "changed"

	again := g.View()

	if again.Cells[0].Glyph == '?' ||
		again.Entities[0].X == 99 ||
		again.Messages[0] == "changed" ||
		again.Inventory[0].Name == "changed" {
		t.Fatalf("view aliases game state: %+v", again)
	}
}
