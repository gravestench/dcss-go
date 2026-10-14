package character

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/content"
)

func TestDeepElfFighterStartsWithSpeciesAdjustedSkillLevels(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	profile, err := BuildStartProfile(
		catalog,
		"SP_DEEP_ELF",
		"JOB_FIGHTER",
		"WPN_FLAIL",
	)

	if err != nil {
		t.Fatal(err)
	}

	wantAttributes := Attributes{
		Strength:     13,
		Intelligence: 12,
		Dexterity:    14,
	}

	if profile.Attributes != wantAttributes ||
		profile.MaxHP != 13 || profile.MaxMP != 3 {
		t.Fatalf("Deep Elf profile = %+v", profile)
	}

	wantSkills := []Skill{
		{
			ID:     "SK_FIGHTING",
			Level:  2,
			Points: 301,
		},

		{
			ID:     "SK_SHIELDS",
			Level:  2,
			Points: 301,
		},

		{
			ID:     "SK_ARMOUR",
			Level:  2,
			Points: 301,
		},

		{
			ID:     "SK_MACES_FLAILS",
			Level:  1,
			Points: 151,
		},
	}

	if !reflect.DeepEqual(profile.Skills, wantSkills) {
		t.Fatalf("Deep Elf skills = %+v, want %+v", profile.Skills, wantSkills)
	}
}
