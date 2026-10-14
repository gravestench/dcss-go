package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

func seedForEarlyGear(
	t *testing.T,
	catalog content.Catalog,
	monsterID string,
	depth int,
	wantPrimary string,
	wantAmmo string,
) (uint64, monster.EarlyHumanoidLoadout, map[string]uint64) {
	t.Helper()

	definition, err := catalog.Monster(monsterID)

	if err != nil {
		t.Fatal(err)
	}

	for seed := uint64(1); seed < 10000; seed++ {
		rng := NewRNGStreams(seed)

		if _, err := monster.RollHP(rng, definition.AverageHP10x); err != nil {
			t.Fatal(err)
		}

		loadout, err := monster.RollEarlyHumanoidLoadout(rng, catalog, monsterID, depth)

		if err != nil {
			t.Fatal(err)
		}

		if (wantPrimary == "" || loadout.Primary.KindID == wantPrimary) &&
			(wantAmmo == "" || loadout.Ammunition.KindID == wantAmmo) {
			return seed, loadout, rng.States()
		}
	}

	t.Fatalf("no seed produced %s gear %s/%s", monsterID, wantPrimary, wantAmmo)

	return 0, monster.EarlyHumanoidLoadout{}, nil
}

func heldMonsterItems(g *Game, monsterID akara.Entity) map[string]ecs.Item {
	held := make(map[string]ecs.Item)

	for _, itemID := range g.stores.CarriedBy.Entities() {
		carrier, found := g.stores.CarriedBy.Get(itemID)

		if !found || carrier.Holder != monsterID {
			continue
		}

		slot, found := g.stores.Equipped.Get(itemID)

		if !found {
			continue
		}

		item, found := g.stores.Items.Get(itemID)

		if found {
			held[slot.Slot] = *item
		}
	}

	return held
}

func TestGoblinSpawnCreatesSlingAndAlternateItems(t *testing.T) {
	g := newStepGame(t)
	seed, want, states := seedForEarlyGear(
		t,
		g.catalog,
		"MONS_GOBLIN",
		1,
		"WPN_SLING",
		"",
	)

	g.rng = NewRNGStreams(seed)

	monsterID, err := newOrdinaryMonsterFactory(g).Spawn("MONS_GOBLIN", 1, 2, 1)

	if err != nil {
		t.Fatal(err)
	}

	held := heldMonsterItems(g, monsterID)

	if len(held) != 2 ||
		held["weapon"].KindID != want.Primary.KindID ||
		held["alternate_weapon"].KindID != want.Alternate.KindID ||
		held["weapon"].Plus != want.Primary.Quality.Plus ||
		held["alternate_weapon"].Ego != want.Alternate.Quality.Ego {
		t.Fatalf("goblin items = %+v, want %+v", held, want)
	}

	if !reflect.DeepEqual(g.rng.States(), states) {
		t.Fatal("goblin creation changed the expected gear draw order")
	}
}

func TestKoboldSpawnCreatesPoisonedDartStack(t *testing.T) {
	g := newStepGame(t)
	seed, want, states := seedForEarlyGear(
		t,
		g.catalog,
		"MONS_KOBOLD",
		2,
		"",
		"MI_DART",
	)

	g.rng = NewRNGStreams(seed)

	monsterID, err := newOrdinaryMonsterFactory(g).Spawn("MONS_KOBOLD", 2, 2, 1)

	if err != nil {
		t.Fatal(err)
	}

	held := heldMonsterItems(g, monsterID)

	if len(held) != 2 ||
		held["weapon"].KindID != want.Primary.KindID ||
		held["missile"].KindID != "MI_DART" ||
		held["missile"].Quantity != want.Ammunition.Quantity ||
		held["missile"].Ego != "poisoned" {
		t.Fatalf("kobold items = %+v, want %+v", held, want)
	}

	if !reflect.DeepEqual(g.rng.States(), states) {
		t.Fatal("kobold creation changed the expected gear draw order")
	}
}

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

func TestEarlyHumanoidEquipmentSurvivesSaveRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 73)
	factory := newOrdinaryMonsterFactory(g)

	for _, monsterID := range []string{
		"MONS_GOBLIN",
		"MONS_KOBOLD",
	} {
		depth := 1

		if monsterID == "MONS_KOBOLD" {
			depth = 2
		}

		level := g.levels[depth]
		cell := firstOpenMonsterCell(t, level)
		actor, err := factory.Spawn(monsterID, depth, cell.x, cell.y)

		if err != nil {
			t.Fatal(err)
		}

		if len(heldMonsterItems(g, actor)) == 0 {
			t.Fatalf("%s has no created equipment", monsterID)
		}

		// A generator accounts for each actor in its initial actor budget.
		level.initialActors++
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("early humanoid equipment changed on restore")
	}
}

func TestEarlyHumanoidItemCreationRollsBackPartialLoadout(t *testing.T) {
	g := newStepGame(t)
	factory := newOrdinaryMonsterFactory(g)
	before := len(g.stores.Items.Entities())
	loadout := monster.EarlyHumanoidLoadout{
		Primary: monster.StartingWeapon{
			KindID: "WPN_CLUB",
		},
		Alternate: monster.StartingWeapon{
			KindID: "WPN_MISSING",
		},
	}

	if _, err := factory.createEarlyHumanoidItems(ratID(t, g), loadout); err == nil {
		t.Fatal("accepted a missing alternate weapon")
	}

	if got := len(g.stores.Items.Entities()); got != before {
		t.Fatalf("partial loadout left %d items, began with %d", got, before)
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
