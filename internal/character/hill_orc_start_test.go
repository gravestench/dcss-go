package character

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/content"
)

func TestHillOrcFighterStartUsesSourceAptitudesAndVitals(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	profile, err := BuildStartProfile(
		catalog,
		"SP_HILL_ORC",
		"JOB_FIGHTER",
		"WPN_FLAIL",
	)

	if err != nil {
		t.Fatal(err)
	}

	wantAttributes := Attributes{
		Strength:     18,
		Intelligence: 8,
		Dexterity:    10,
	}

	if profile.Attributes != wantAttributes ||
		profile.MaxHP != 19 || profile.MaxMP != 1 {
		t.Fatalf("Hill Orc profile = %+v", profile)
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
			ID:     "SK_MACES_FLAILS",
			Level:  2,
			Points: 151,
		},
	}

	if !reflect.DeepEqual(profile.Skills, wantSkills) {
		t.Fatalf("Hill Orc skills = %+v, want %+v", profile.Skills, wantSkills)
	}
}

func TestStartingSkillReassessmentUsesStrictSpeciesThreshold(t *testing.T) {
	for _, tc := range []struct {
		points   int
		aptitude int
		want     int
	}{
		{
			points:   301,
			aptitude: -2,
			want:     2,
		},

		{
			points:   301,
			aptitude: 0,
			want:     3,
		},

		{
			points:   301,
			aptitude: 4,
			want:     4,
		},
	} {
		got, err := reassessedStartingLevel(tc.points, tc.aptitude)

		if err != nil ||
			got != tc.want {
			t.Fatalf("points %d at aptitude %+d = %d, %v; want %d",
				tc.points, tc.aptitude, got, err, tc.want)
		}
	}
}
