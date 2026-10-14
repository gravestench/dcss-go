package game

import "testing"

func TestSaveAcceptsCatalogedMonsterWeaponBrand(t *testing.T) {
	g := newStepGame(t)
	weaponID := giveTestMonsterWeapon(t, g, ratID(t, g))
	weapon, found := g.stores.Items.Get(weaponID)

	if !found {
		t.Fatal("missing test weapon")
	}

	weapon.Ego = "SPWPN_VENOM"

	loaded, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	restored, found := loaded.stores.Items.Get(weaponID)

	if !found || restored.Ego != weapon.Ego {
		t.Fatalf("restored weapon = %+v", restored)
	}
}

func firstOpenMonsterCell(t *testing.T, level *Level) point {
	t.Helper()

	for y, row := range level.terrain {
		for x := range row {
			if !level.Walkable(x, y) {
				continue
			}

			if _, occupied := level.ActorAt(x, y); !occupied {
				return point{
					x: x,
					y: y,
				}
			}
		}
	}

	t.Fatal("generated Dungeon has no open monster cell")

	return point{}
}
