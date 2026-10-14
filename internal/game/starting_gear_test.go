package game

import (
	"reflect"
	"slices"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestNewScenarioStartingGear(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	for _, weaponID := range []string{
		"WPN_RAPIER",
		"WPN_FLAIL",
		"WPN_WAR_AXE",
		"WPN_TRIDENT",
		"WPN_LONG_SWORD",
		"WPN_UNARMED",
	} {
		t.Run(weaponID, func(t *testing.T) {
			g, err := NewScenario(7, catalog, weaponID, "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			player, found := g.stores.Players.Get(g.player)

			if !found || player.StartingWeaponID != weaponID {
				t.Fatalf("selected weapon = %+v", player)
			}

			view := g.View()
			wantKinds := []string{
				"ARM_SCALE_MAIL",
				"ARM_BUCKLER",
				"POT_MIGHT",
			}

			wantSlots := []string{
				"body",
				"shield",
				"",
			}

			if weaponID != "WPN_UNARMED" {
				wantKinds = append([]string{weaponID}, wantKinds...)
				wantSlots = append([]string{"weapon"}, wantSlots...)
			}

			gotKinds, gotSlots := []string{}, []string{}

			for _, item := range view.Inventory {
				gotKinds, gotSlots = append(gotKinds, item.KindID), append(gotSlots, item.Slot)

				if item.Quantity != 1 {
					t.Fatalf("wrong starter quantity: %+v", item)
				}
			}

			if !slices.Equal(gotKinds, wantKinds) || !slices.Equal(gotSlots, wantSlots) {
				t.Fatalf("loadout kinds/slots = %v/%v, want %v/%v", gotKinds, gotSlots, wantKinds, wantSlots)
			}

			if view.CurrentAut != 0 || view.PlayerHP != 18 || view.PlayerMaxHP != 18 {
				t.Fatalf("scenario start changed time or HP: %+v", view)
			}

			combat, found := g.stores.Combat.Get(g.player)

			if !found || combat.ShieldBlocks != 0 {
				t.Fatalf("initial combat state = %+v", combat)
			}

			floorPotion, carried := false, 0

			for _, record := range g.Snapshot().Entities {
				if record.Item == nil {
					continue
				}

				if record.Item.KindID == "POT_CURING" && record.Position != nil {
					floorPotion = true
				}

				if record.CarriedBy != nil {
					carried++

					if record.CarriedBy.Holder != g.player {
						t.Fatalf("wrong carrier: %+v", record)
					}

					if record.Equipped != nil && record.Equipped.Slot == "" {
						t.Fatalf("empty equipped slot: %+v", record)
					}
				}
			}

			if !floorPotion || carried != len(wantKinds) {
				t.Fatalf("floor potion or carried items missing: floor=%v carried=%d", floorPotion, carried)
			}
		})
	}

	if g, err := NewScenario(7, catalog, "WPN_QUARTERSTAFF", "Tester"); err == nil {
		g.Close()
		t.Fatal("banned weapon accepted")
	}
}

func TestSaveStartingGearContinuation(t *testing.T) {
	g, err := NewScenario(19, testCatalog(t), "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	for _, extra := range []ecs.Item{
		{
			KindID:   "WAND_CHARMING",
			Quantity: 1,
			Charges:  15,
		},

		{
			KindID:   "MI_DART",
			Quantity: 3,
			Ego:      "curare",
		},
	} {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.Items.Set(entity, extra); err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{Holder: g.player}); err != nil {
			t.Fatal(err)
		}
	}

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)

		if item.KindID == "WPN_RAPIER" {
			item.Plus = 2

			if _, err := g.stores.Items.Set(entity, *item); err != nil {
				t.Fatal(err)
			}
		}
	}

	before := g.Snapshot()
	restored, err := Restore(before, testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("loadout properties or slots lost on restore")
	}

	for _, command := range []Command{
		{Kind: CommandWait},
		{
			Kind: CommandMove,
			DX:   1,
		},
	} {
		left, leftErr := g.Step(command)
		right, rightErr := restored.Step(command)

		if leftErr != nil || rightErr != nil || !reflect.DeepEqual(left, right) {
			t.Fatalf("continuation differs: %+v/%v vs %+v/%v", left, leftErr, right, rightErr)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("seeded continuation diverged")
	}
}

func TestRestoreRejectsCorruptGear(t *testing.T) {
	for _, tc := range []struct {
		name   string
		mutate func(*save.Snapshot)
	}{
		{
			name: "duplicate slot",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil &&
						s.Entities[i].Item.KindID == "ARM_BUCKLER" {
						s.Entities[i].Equipped.Slot = "body"
					}
				}
			},
		},

		{
			name: "equipped without carrier",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Equipped != nil {
						s.Entities[i].CarriedBy = nil
						s.Entities[i].Position = &ecs.Position{
							LevelID: 1,
							X:       2,
							Y:       2,
						}

						return
					}
				}
			},
		},

		{
			name: "zero quantity",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil {
						s.Entities[i].Item.Quantity = 0

						return
					}
				}
			},
		},

		{
			name: "charges on potion",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil && s.Entities[i].Item.KindID == "POT_MIGHT" {
						s.Entities[i].Item.Charges = 5

						return
					}
				}
			},
		},

		{
			name: "ego on potion",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil && s.Entities[i].Item.KindID == "POT_MIGHT" {
						s.Entities[i].Item.Ego = "curare"

						return
					}
				}
			},
		},

		{
			name: "changed selected weapon",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Player != nil {
						s.Entities[i].Player.StartingWeaponID = "WPN_FLAIL"

						return
					}
				}
			},
		},

		{
			name: "unknown kind",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil {
						s.Entities[i].Item.KindID = "WPN_UNKNOWN"

						return
					}
				}
			},
		},

		{
			name: "missing weapon",
			mutate: func(s *save.Snapshot) {
				for i := range s.Entities {
					if s.Entities[i].Item != nil && s.Entities[i].Item.KindID == "WPN_RAPIER" {
						s.Entities = append(s.Entities[:i], s.Entities[i+1:]...)

						return
					}
				}
			},
		},

		{
			name: "version two",
			mutate: func(s *save.Snapshot) {
				s.Version = 2
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			g, err := NewScenario(23, testCatalog(t), "WPN_RAPIER", "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			before := g.Snapshot()
			bad := g.Snapshot()
			tc.mutate(&bad)

			if replacement, err := g.Restore(bad); err == nil {
				replacement.Close()
				t.Fatal("corrupt gear accepted")
			}

			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore changed live game")
			}
		})
	}
}
