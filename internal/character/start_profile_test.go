package character

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
)

func TestBuildStartProfileHumanFighter(t *testing.T) {
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct{ weapon, skill string }{
		{"WPN_FLAIL", "SK_MACES_FLAILS"},
		{"WPN_UNARMED", "SK_UNARMED_COMBAT"},
	} {
		t.Run(tc.weapon, func(t *testing.T) {
			got, err := BuildStartProfile(catalog, "SP_HUMAN", "JOB_FIGHTER", tc.weapon)
			if err != nil {
				t.Fatal(err)
			}
			if got.Attributes != (Attributes{Strength: 16, Intelligence: 8, Dexterity: 12}) || got.MaxHP != 18 || got.MaxMP != 1 {
				t.Fatalf("profile = %+v, want 16/8/12, HP 18, MP 1", got)
			}
			wantSkills := []Skill{
				{ID: "SK_FIGHTING", Level: 3, Points: 301},
				{ID: "SK_SHIELDS", Level: 3, Points: 301},
				{ID: "SK_ARMOUR", Level: 3, Points: 301},
				{ID: tc.skill, Level: 2, Points: 151},
			}
			if !reflect.DeepEqual(got.Skills, wantSkills) {
				t.Fatalf("skills = %+v, want %+v", got.Skills, wantSkills)
			}
			got.Skills[0].Points = -1
			again, err := BuildStartProfile(catalog, "SP_HUMAN", "JOB_FIGHTER", tc.weapon)
			if err != nil || !reflect.DeepEqual(again.Skills, wantSkills) {
				t.Fatalf("later skills = %+v, err = %v, want %+v", again.Skills, err, wantSkills)
			}
		})
	}
}

func TestBuildStartProfileRejectsBadChoice(t *testing.T) {
	catalog, err := content.LoadDefault()
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct{ species, job, weapon string }{
		{"SP_HUMAN", "JOB_FIGHTER", "WPN_QUARTERSTAFF"},
		{"SP_HILL_ORC", "JOB_FIGHTER", "WPN_FLAIL"},
	} {
		got, err := BuildStartProfile(catalog, tc.species, tc.job, tc.weapon)
		if err == nil || !reflect.DeepEqual(got, StartProfile{}) || !strings.Contains(err.Error(), tc.job) {
			t.Fatalf("choice %+v: got %+v, err %v", tc, got, err)
		}
	}
}
