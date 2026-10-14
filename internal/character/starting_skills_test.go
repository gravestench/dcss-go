package character

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestStartingSkillsHumanFighterWeapons(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

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
			got, err := StartingSkills(catalog, "SP_HUMAN", "JOB_FIGHTER", tc.weapon)

			if err != nil {
				t.Fatal(err)
			}

			want := []Skill{
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

			if !reflect.DeepEqual(got, want) {
				t.Fatalf("skills = %+v, want %+v", got, want)
			}

			got[0].Points = -1
			again, err := StartingSkills(catalog, "SP_HUMAN", "JOB_FIGHTER", tc.weapon)

			if err != nil || !reflect.DeepEqual(again, want) {
				t.Fatalf("later skills = %+v, err = %v, want %+v", again, err, want)
			}
		})
	}
}

func TestStartingSkillsRejectsUnsupportedChoice(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		species string
		job     string
		weapon  string
	}{
		{
			species: "SP_HILL_ORC",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_FLAIL",
		},

		{
			species: "SP_HUMAN",
			job:     "JOB_GLADIATOR",
			weapon:  "WPN_FLAIL",
		},

		{
			species: "SP_HUMAN",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_QUARTERSTAFF",
		},
	} {
		got, err := StartingSkills(catalog, tc.species, tc.job, tc.weapon)

		if err == nil ||
			len(got) != 0 || !strings.Contains(err.Error(), tc.job) {
			t.Fatalf("choice %+v: got %+v, err %v", tc, got, err)
		}
	}
}

func TestResolveChosenWeaponSkillRejectsBadKind(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	species, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	for _, skill := range []string{"", "SK_UNKNOWN"} {
		kind := content.ItemDef{
			ID:          "WPN_BROKEN",
			Class:       "OBJ_WEAPONS",
			WeaponSkill: skill,
		}

		got, err := resolveChosenWeaponSkill(kind, species)

		if err == nil ||
			got != "" || !strings.Contains(err.Error(), kind.ID) {
			t.Fatalf("skill %q: got %q, err %v", skill, got, err)
		}
	}
}
