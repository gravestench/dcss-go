package game

import (
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func carriedTestWand(t *testing.T, g *Game, kind string, charges int) uint64 {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	item := ecs.Item{
		KindID:   kind,
		Quantity: 1,
		Charges:  charges,
	}

	if _, err := g.stores.Items.Set(entity, item); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{
		Holder: g.player,
	}); err != nil {
		t.Fatal(err)
	}

	return uint64(entity)
}

func TestWandEvokeConsumesChargeAndMPWandsResource(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_MP_WANDS")
	wand := carriedTestWand(t, g, "WAND_DIGGING", 2)

	magic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("player lacks MP")
	}

	magic.Current = 3
	magic.Max = max(magic.Max, 3)

	beforeAut := g.View().CurrentAut
	result, err := g.Step(Command{
		Kind:   CommandEvokeWand,
		ItemID: wand,
		DX:     1,
	})

	if err != nil {
		t.Fatal(err)
	}

	item, found := g.stores.Items.Get(akara.Entity(wand))

	if !found ||
		item.Charges != 1 ||
		result.Spent != 10 ||
		g.View().CurrentAut != beforeAut+10 ||
		magic.Current != 0 {
		t.Fatalf("wand use: item=%+v found=%v spent=%d MP=%d",
			item, found, result.Spent, magic.Current)
	}

	_, err = g.Step(Command{
		Kind:   CommandEvokeWand,
		ItemID: wand,
		DX:     1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if _, found := g.stores.Items.Get(akara.Entity(wand)); found {
		t.Fatal("empty wand did not crumble")
	}
}

func TestWandEvokeRejectsInvalidSelectionWithoutTime(t *testing.T) {
	g := newStepGame(t)
	wand := carriedTestWand(t, g, "WAND_DIGGING", 1)
	beforeAut := g.View().CurrentAut

	for _, command := range []Command{
		{
			Kind:   CommandEvokeWand,
			ItemID: wand,
		},

		{
			Kind:   CommandEvokeWand,
			ItemID: 999999,
			DX:     1,
		},
	} {
		result, err := g.Step(command)

		if err != nil {
			t.Fatal(err)
		}

		if result.Spent != 0 || g.View().CurrentAut != beforeAut {
			t.Fatalf("invalid wand selection spent time: %+v", command)
		}
	}
}

func TestEverySourceWandResolvesARealTurn(t *testing.T) {
	for _, kind := range []string{
		"WAND_FLAME",
		"WAND_PARALYSIS",
		"WAND_DIGGING",
		"WAND_ICEBLAST",
		"WAND_POLYMORPH",
		"WAND_CHARMING",
		"WAND_ACID",
		"WAND_LIGHT",
		"WAND_QUICKSILVER",
		"WAND_MINDBURST",
		"WAND_ROOTS",
	} {
		t.Run(kind, func(t *testing.T) {
			g := newStepGame(t)
			wand := carriedTestWand(t, g, kind, 1)
			view := g.View()
			var target *EntityView

			for index := range view.Entities {
				if view.Entities[index].Role == "monster" {
					target = &view.Entities[index]

					break
				}
			}

			if target == nil {
				t.Fatal("fixed scenario has no monster target")
			}

			result, err := g.Step(Command{
				Kind:   CommandEvokeWand,
				ItemID: wand,
				DX:     target.X - view.PlayerX,
				DY:     target.Y - view.PlayerY,
			})

			if err != nil {
				t.Fatal(err)
			}

			if result.Spent != 10 {
				t.Fatalf("wand turn spent %d aut", result.Spent)
			}

			if _, found := g.stores.Items.Get(akara.Entity(wand)); found {
				t.Fatal("last wand charge was not consumed")
			}
		})
	}
}

func TestWandChargeContinuesAcrossSave(t *testing.T) {
	g := newStepGame(t)
	wand := carriedTestWand(t, g, "WAND_DIGGING", 2)
	command := Command{
		Kind:   CommandEvokeWand,
		ItemID: wand,
		DX:     1,
	}

	if _, err := g.Step(command); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	item, found := restored.stores.Items.Get(akara.Entity(wand))

	if !found || item.Charges != 1 {
		t.Fatalf("saved wand charge = %+v, found %v", item, found)
	}

	if _, err := restored.Step(command); err != nil {
		t.Fatal(err)
	}

	if _, found := restored.stores.Items.Get(akara.Entity(wand)); found {
		t.Fatal("restored wand did not crumble on its final charge")
	}
}
