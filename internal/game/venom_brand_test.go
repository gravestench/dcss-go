package game

import (
	"github.com/gravestench/akara"
	"testing"
)

func setMonsterPrimaryBrand(
	t *testing.T,
	g *Game,
	monsterID akara.Entity,
	brand string,
) {
	t.Helper()

	for _, itemID := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		slot, found := g.stores.Equipped.Get(itemID)

		if !found || slot.Slot != "weapon" {
			continue
		}

		item, found := g.stores.Items.Get(itemID)

		if !found {
			t.Fatal("monster weapon has no item")
		}

		item.Ego = brand

		return
	}

	t.Fatal("monster has no primary weapon")
}
