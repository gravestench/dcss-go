package character

import (
	"slices"
	"testing"

	"dcrawl-go/internal/content"
)

func TestHumanFighterWeaponOptions(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	options, err := WeaponOptions(catalog, "SP_HUMAN", "JOB_FIGHTER")

	if err != nil {
		t.Fatal(err)
	}

	ids := make([]string, 0, len(options))

	for _, option := range options {
		ids = append(ids, option.ID)

		if option.Name == "" {
			t.Fatalf("unnamed option: %+v", option)
		}
	}

	if !slices.Equal(
		ids,
		[]string{
			"WPN_RAPIER",
			"WPN_FLAIL",
			"WPN_WAR_AXE",
			"WPN_TRIDENT",
			"WPN_LONG_SWORD",
			"WPN_UNARMED",
		},
	) {
		t.Fatalf("Fighter choices = %v", ids)
	}

	if options[0].Restriction != Restricted ||
		options[1].Restriction != Recommended ||
		options[2].Restriction != Recommended ||
		options[3].Restriction != Recommended ||
		options[4].Restriction != Recommended ||
		options[5].Restriction != Restricted {
		t.Fatalf("Fighter recommendations = %+v", options)
	}

	for _, id := range ids {
		if err := ValidateWeaponChoice(catalog, "SP_HUMAN", "JOB_FIGHTER", id); err != nil {
			t.Fatalf("legal choice %s rejected: %v", id, err)
		}
	}

	if err := ValidateWeaponChoice(catalog, "SP_HUMAN", "JOB_FIGHTER", "WPN_QUARTERSTAFF"); err == nil {
		t.Fatal("quarterstaff accepted for Human Fighter")
	}
}

func TestWeaponChoiceRestrictions(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		species string
		job     string
		want    string
	}{
		{
			species: "SP_KOBOLD",
			job:     "JOB_FIGHTER",
			want:    "WPN_SPEAR",
		},

		{
			species: "SP_HUMAN",
			job:     "JOB_GLADIATOR",
			want:    "WPN_QUARTERSTAFF",
		},

		{
			species: "SP_FORMICID",
			job:     "JOB_FIGHTER",
			want:    "WPN_QUARTERSTAFF",
		},

		{
			species: "SP_FELID",
			job:     "JOB_FIGHTER",
			want:    "WPN_UNARMED",
		},
	} {
		options, err := WeaponOptions(catalog, tc.species, tc.job)

		if err != nil {
			t.Fatalf("%s/%s: %v", tc.species, tc.job, err)
		}

		if !slices.ContainsFunc(options, func(o WeaponOption) bool {
			return o.ID == tc.want
		}) {
			t.Fatalf("%s/%s lacks %s: %+v", tc.species, tc.job, tc.want, options)
		}

		if tc.species == "SP_KOBOLD" && slices.ContainsFunc(
			options,
			func(o WeaponOption) bool {
				return o.ID == "WPN_TRIDENT"
			},
		) {
			t.Fatal("small Fighter spear was upgraded to trident")
		}

		if tc.species == "SP_FELID" &&
			(len(options) != 1 ||
				options[0].Restriction != Recommended) {
			t.Fatalf("no-grasping Felid has grasped choices: %+v", options)
		}
	}

	for _, tc := range []struct {
		species string
		job     string
		weapon  string
	}{
		{
			species: "SP_UNKNOWN",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_RAPIER",
		},

		{
			species: "SP_HUMAN",
			job:     "JOB_UNKNOWN",
			weapon:  "WPN_RAPIER",
		},

		{
			species: "SP_HUMAN",
			job:     "JOB_FIGHTER",
			weapon:  "WPN_UNKNOWN",
		},

		{
			species: "SP_FELID",
			job:     "JOB_GLADIATOR",
			weapon:  "WPN_UNARMED",
		},
	} {
		if err := ValidateWeaponChoice(catalog, tc.species, tc.job, tc.weapon); err == nil {
			t.Fatalf("invalid choice accepted: %+v", tc)
		}
	}

	before, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	_, _ = WeaponOptions(catalog, "SP_HUMAN", "JOB_FIGHTER")
	after, err := catalog.Species("SP_HUMAN")

	if err != nil ||
		!slices.Equal(before.RecommendedWeapons, after.RecommendedWeapons) {
		t.Fatalf("weapon choices mutated catalog: %+v, %v", after, err)
	}
}
