package character

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/content"
)

func TestMinotaurFighterStartUsesInnateSpeciesProfile(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	profile, err := BuildStartProfile(
		catalog,
		"SP_MINOTAUR",
		"JOB_FIGHTER",
		"WPN_FLAIL",
	)

	if err != nil {
		t.Fatal(err)
	}

	wantAttributes := Attributes{
		Strength:     20,
		Intelligence: 5,
		Dexterity:    9,
	}

	if profile.Attributes != wantAttributes ||
		profile.MaxHP != 19 ||
		profile.MaxMP != 0 {
		t.Fatalf("Minotaur profile = %+v", profile)
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
		t.Fatalf("Minotaur skills = %+v, want %+v", profile.Skills, wantSkills)
	}
}
