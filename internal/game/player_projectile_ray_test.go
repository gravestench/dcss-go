package game

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
)

func cloneRatOnRay(t *testing.T, g *Game, x, y int) {
	t.Helper()
	first := ratID(t, g)
	actor, _ := g.stores.Actors.Get(first)
	health, _ := g.stores.Health.Get(first)
	ai, _ := g.stores.AI.Get(first)
	energy, _ := g.stores.MonsterEnergy.Get(first)
	combat, _ := g.stores.Combat.Get(first)
	second, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(second, *actor); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(second, *health); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(second, *ai); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(second, *energy); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(second, *combat); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].PlaceActor(second, x, y); err != nil {
		t.Fatal(err)
	}
}

func TestMissedProjectileContinuesToSecondActor(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		cloneRatOnRay(t, g, 5, 1)
		equipPlayerLauncher(t, g, "WPN_SLING")
		result, err := g.Step(Command{
			Kind: CommandFire,
			DX:   2,
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		contacts := 0
		firstMissed := false

		for _, event := range result.Events {
			if strings.Contains(event.Text, "sling bullet") &&
				strings.Contains(event.Text, "the rat") {
				contacts++

				if contacts == 1 && strings.Contains(event.Text, "misses") {
					firstMissed = true
				}
			}
		}

		if firstMissed {
			if contacts != 2 {
				t.Fatalf("missed shot touched %d actors, want 2", contacts)
			}

			return
		}
	}

	t.Fatal("no first-actor miss across tested seeds")
}

func TestThrownNetContinuesBeyondAimCell(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 1, 6); err != nil {
		t.Fatal(err)
	}

	netID := givePlayerProjectileItem(t, g, "MI_THROWING_NET", 1, "")
	_, err := g.Step(Command{
		Kind:   CommandThrow,
		DX:     1,
		ItemID: uint64(netID),
	})

	if err != nil {
		t.Fatal(err)
	}

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, found := g.stores.Positions.Get(entity)

		if item.KindID != "MI_THROWING_NET" || !found {
			continue
		}

		if *position != (ecs.Position{
			LevelID: 1,
			X:       7,
			Y:       6,
		}) {
			t.Fatalf("net landed at %+v, want ray endpoint (7,6)", position)
		}

		return
	}

	t.Fatal("thrown net did not land on the floor")
}

func TestNeedleCanBeThrownWithoutLauncher(t *testing.T) {
	g := newStepGame(t)
	needle := givePlayerProjectileItem(t, g, "MI_NEEDLE", 2, "")
	result, err := g.Step(Command{
		Kind:   CommandThrow,
		DX:     1,
		ItemID: uint64(needle),
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent <= 0 {
		t.Fatal("throwing a needle spent no time")
	}

	item, found := g.stores.Items.Get(needle)

	if !found || item.Quantity != 1 {
		t.Fatalf("needle stack = %+v, found=%v", item, found)
	}
}

func TestWieldedLauncherHasNoMeleeWeaponDamage(t *testing.T) {
	for seed := uint64(1); seed <= 20; seed++ {
		g, err := NewScenario(seed, "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
			g.Close()
			t.Fatal(err)
		}

		equipPlayerLauncher(t, g, "WPN_TRIPLE_CROSSBOW")
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		g.Close()

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "You hit the rat") {
				if event.Text != "You hit the rat but do no damage." {
					t.Fatalf("launcher melee: %q", event.Text)
				}

				return
			}
		}
	}

	t.Fatal("no launcher melee hit across tested seeds")
}
