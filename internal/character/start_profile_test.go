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

	for _, tc := range []struct {
		weapon string
		skill  string
	}{
		{
			weapon: "WPN_FLAIL",
			skill:  "SK_MACES_FLAILS",
		},
		{
			weapon: "WPN_UNARMED",
			skill:  "SK_UNARMED_COMBAT",
		},
	} {
		t.Run(tc.weapon, func(t *testing.T) {
			got, err := BuildStartProfile(catalog, "SP_HUMAN", "JOB_FIGHTER", tc.weapon)

			if err != nil {
				t.Fatal(err)
			}

			if got.Attributes != (Attributes{
				Strength:     16,
				Intelligence: 8,
				Dexterity:    12,
			}) || got.MaxHP != 18 || got.MaxMP != 1 {
				t.Fatalf("profile = %+v, want 16/8/12, HP 18, MP 1", got)
			}

			wantSkills := []Skill{
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

func TestScaledStartingSkillsRetainFractionalProgress(t *testing.T) {
	if got := ScaledSkill(Skill{
		ID:     "SK_FIGHTING",
		Level:  3,
		Points: 301,
	}, 100); got != 300 {
		t.Fatalf("Fighting at scale 100 = %d, want 300", got)
	}

	if got := ScaledSkill(Skill{
		ID:     "SK_MACES_FLAILS",
		Level:  2,
		Points: 151,
	}, 100); got != 200 {
		t.Fatalf("weapon at scale 100 = %d, want 200", got)
	}

	if got := ScaledSkill(Skill{
		ID:     "SK_UNARMED_COMBAT",
		Level:  2,
		Points: 151,
	}, 256); got != 513 {
		t.Fatalf("unarmed at scale 256 = %d, want 513", got)
	}
}

func TestBuildStartProfileRejectsBadChoice(t *testing.T) {
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
			species: "SP_HUMAN",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_QUARTERSTAFF",
		},
		{
			species: "SP_HILL_ORC",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_FLAIL",
		},
	} {
		got, err := BuildStartProfile(catalog, tc.species, tc.job, tc.weapon)

		if err == nil || !reflect.DeepEqual(got, StartProfile{}) || !strings.Contains(err.Error(), tc.job) {
			t.Fatalf("choice %+v: got %+v, err %v", tc, got, err)
		}
	}
}
