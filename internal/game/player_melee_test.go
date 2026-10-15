package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestPlayerBumpAndSaveContinueWithSourceMelee(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
	command := Command{
		Kind: CommandMove,
		DX:   1,
	}

	left, leftErr := g.Step(command)
	right, rightErr := loaded.Step(command)

	if leftErr != nil ||
		rightErr != nil ||
		!reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("post-load bump differs: %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	if (left.Spent != 11 &&
		left.Spent != 12) ||
		left.View.CurrentAut != left.Spent {
		t.Fatalf("bump cost = %d at aut %d", left.Spent, left.View.CurrentAut)
	}
}

func TestPlayerLethalBumpClearsRatOccupancy(t *testing.T) {
	g, err := NewScenario(7, "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if (result.Spent != 11 &&
		result.Spent != 12) || g.world.EntityExists(rat) {
		t.Fatalf(
			"lethal bump spent %d aut, rat still exists %v; events %+v",
			result.Spent,
			g.world.EntityExists(rat),
			result.Events,
		)
	}

	if _, occupied := g.levels[1].ActorAt(4, 1); occupied {
		t.Fatal("dead rat remains in occupancy index")
	}
}

func TestPlayerBumpRejectsInvalidWeaponBeforeSpendingTime(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*ecs.Item)
	}{
		{
			name: "extreme enchantment",
			mutate: func(item *ecs.Item) {
				item.Plus = 101
			},
		},

		{
			name: "zero quantity",
			mutate: func(item *ecs.Item) {
				item.Quantity = 0
			},
		},

		{
			name: "duplicate weapon quantity",
			mutate: func(item *ecs.Item) {
				item.Quantity = 2
			},
		},

		{
			name: "charges on weapon",
			mutate: func(item *ecs.Item) {
				item.Charges = 1
			},
		},

		{
			name: "unsupported ego",
			mutate: func(item *ecs.Item) {
				item.Ego = "poisoned"
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)

			if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
				t.Fatal(err)
			}

			for _, entity := range g.stores.Equipped.Entities() {
				item, found := g.stores.Items.Get(entity)

				if found && item.KindID == "WPN_RAPIER" {
					tc.mutate(item)
				}
			}

			before := g.Snapshot()

			if _, err := g.Step(Command{
				Kind: CommandMove,
				DX:   1,
			}); err == nil {
				t.Fatal("invalid weapon bump accepted")
			}

			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed bump changed game state")
			}
		})
	}
}

func TestRestoreRejectsUnsupportedPlayerMeleeState(t *testing.T) {
	for _, tc := range []struct {
		name   string
		want   string
		change func(*save.Snapshot)
	}{
		{
			name: "extreme weapon plus",
			want: "attack",
			change: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil && s.Entities[i].Item.KindID == "WPN_RAPIER" {
						s.Entities[i].Item.Plus = 101
					}
				}
			},
		},

		{
			name: "mismatched weapon",
			want: "weapon",
			change: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil && s.Entities[i].Item.KindID == "WPN_RAPIER" {
						s.Entities[i].Item.KindID = "WPN_FLAIL"
					}
				}
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g := newStepGame(t)
			before := g.Snapshot()
			bad := g.Snapshot()
			tc.change(&bad)

			if restored, err := g.Restore(bad); err == nil {
				restored.Close()
				t.Fatal("invalid player melee state restored")
			} else if !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("restore error %q does not contain %q", err, tc.want)
			}

			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore changed live game")
			}
		})
	}
}
