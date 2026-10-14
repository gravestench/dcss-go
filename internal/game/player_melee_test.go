package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestPlayerMeleeProjectionUsesEveryStartingWeapon(t *testing.T) {
	for _, weaponID := range []string{
		"WPN_RAPIER",
		"WPN_FLAIL",
		"WPN_WAR_AXE",
		"WPN_TRIDENT",
		"WPN_LONG_SWORD",
		"WPN_UNARMED",
	} {
		t.Run(weaponID, func(t *testing.T) {
			catalog := testCatalog(t)
			g, err := NewScenario(3, catalog, weaponID, "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			in, err := newPlayerCombat(g).attackInput("MONS_RAT")

			if err != nil {
				t.Fatal(err)
			}

			if in.Strength != 16 || in.Dexterity != 12 || in.FightingSkill100 != 300 ||
				in.WeaponSkill100 != 200 || in.DefenderEV != 10 || in.DefenderAC != 1 {
				t.Fatalf("source input = %+v", in)
			}

			if weaponID == "WPN_UNARMED" {
				if !in.Unarmed || in.WeaponSkillID != "SK_UNARMED_COMBAT" || in.UnarmedSkill256 != 513 || in.WeaponDamage != 0 {
					t.Fatalf("unarmed input = %+v", in)
				}

				return
			}

			kind, err := catalog.Item(weaponID)

			if err != nil {
				t.Fatal(err)
			}

			if in.Unarmed || in.WeaponSkillID != kind.WeaponSkill || in.WeaponDamage != kind.Weapon.Damage ||
				in.WeaponHit != kind.Weapon.Hit {
				t.Fatalf("%s input = %+v, catalog %+v", weaponID, in, kind.Weapon)
			}

			for _, entity := range g.stores.Equipped.Entities() {
				item, found := g.stores.Items.Get(entity)

				if found && item.KindID == weaponID {
					item.Plus = 2
				}
			}

			in, err = newPlayerCombat(g).attackInput("MONS_RAT")

			if err != nil || in.WeaponPlus != 2 {
				t.Fatalf("enchanted weapon input = %+v, %v", in, err)
			}
		})
	}
}

func TestPlayerBumpAndSaveContinueWithSourceMelee(t *testing.T) {
	g := newStepGame(t)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot(), testCatalog(t))

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

	if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatalf("post-load bump differs: %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
	}

	if (left.Spent != 11 && left.Spent != 12) || left.View.CurrentAut != left.Spent {
		t.Fatalf("bump cost = %d at aut %d", left.Spent, left.View.CurrentAut)
	}
}

func TestPlayerLethalBumpClearsRatOccupancy(t *testing.T) {
	g, err := NewScenario(7, testCatalog(t), "WPN_RAPIER", "Tester")

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

	if (result.Spent != 11 && result.Spent != 12) || g.world.EntityExists(rat) {
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

func TestPlayerMeleeUsesStoredSkillPoints(t *testing.T) {
	g := newStepGame(t)
	skills, _ := g.stores.Skills.Get(g.player)

	for i := range skills.Entries {
		if skills.Entries[i].ID == "SK_SHORT_BLADES" {
			skills.Entries[i] = character.Skill{
				ID:     "SK_SHORT_BLADES",
				Level:  2,
				Points: 299,
			}
		}
	}

	in, err := newPlayerCombat(g).attackInput("MONS_RAT")

	if err != nil || in.WeaponSkill100 <= 200 {
		t.Fatalf("modified skill points ignored: %+v, %v", in, err)
	}
}
