package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/character"
)

func TestScenarioInstallsStartingProfile(t *testing.T) {
	for _, tc := range []struct {
		weapon string
		skill  string
	}{
		{
			weapon: "WPN_RAPIER",
			skill:  "SK_SHORT_BLADES",
		},

		{
			weapon: "WPN_FLAIL",
			skill:  "SK_MACES_FLAILS",
		},

		{
			weapon: "WPN_WAR_AXE",
			skill:  "SK_AXES",
		},

		{
			weapon: "WPN_TRIDENT",
			skill:  "SK_POLEARMS",
		},

		{
			weapon: "WPN_LONG_SWORD",
			skill:  "SK_LONG_BLADES",
		},

		{
			weapon: "WPN_UNARMED",
			skill:  "SK_UNARMED_COMBAT",
		},
	} {
		t.Run(tc.weapon, func(t *testing.T) {
			g, err := NewScenario(37, testCatalog(t), tc.weapon, "Tester")

			if err != nil {
				t.Fatal(err)
			}

			defer g.Close()
			view := g.View()

			if view.CurrentAut != 0 ||
				view.PlayerHP != 18 ||
				view.PlayerMaxHP != 18 ||
				view.PlayerMP != 1 ||
				view.PlayerMaxMP != 1 {
				t.Fatalf("start clocks and pools = %+v", view)
			}

			want := []character.Skill{
				{
					ID:     "SK_FIGHTING",
					Level:  3,
					Points: 301,
				},

				{
					ID:     "SK_SHIELDS",
					Level:  3,
					Points: 301,
				},

				{
					ID:     "SK_ARMOUR",
					Level:  3,
					Points: 301,
				},

				{
					ID:     tc.skill,
					Level:  2,
					Points: 151,
				},
			}

			if !reflect.DeepEqual(view.Skills, want) {
				t.Fatalf("skills = %+v, want %+v", view.Skills, want)
			}

			storedSkills, ok := g.stores.Skills.Get(g.player)

			if !ok || !reflect.DeepEqual(storedSkills.Entries, want) {
				t.Fatalf("player skills component = %+v", storedSkills)
			}

			magic, ok := g.stores.Magic.Get(g.player)

			if !ok || magic.Current != 1 || magic.Max != 1 {
				t.Fatalf("player magic component = %+v", magic)
			}

			wantItems := 4

			if tc.weapon == "WPN_UNARMED" {
				wantItems = 3
			}

			if len(view.Inventory) != wantItems {
				t.Fatalf("starter inventory has %d items, want %d", len(view.Inventory), wantItems)
			}
		})
	}
}

func TestScenarioDamageKeepsMaxHP(t *testing.T) {
	g := newStepGame(t)

	for i := 0; i < 15 && g.View().PlayerHP == 18; i++ {
		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	view := g.View()

	if view.PlayerHP >= 18 || view.PlayerMaxHP != 18 {
		t.Fatalf("damage changed initial max or never happened: HP %d/%d", view.PlayerHP, view.PlayerMaxHP)
	}
}

func TestViewCopiesSkills(t *testing.T) {
	g := newStepGame(t)
	first := g.View()
	first.Skills[0].Points = -99
	second := g.View()

	if second.Skills[0].Points != 301 {
		t.Fatalf("view mutated live skills: %+v", second.Skills)
	}
}
