package monsterweaponimport

import (
	"strings"
	"testing"
)

const fixture = `int make_mons_weapon(monster_type type, int level, bool melee_only)
{
    static const weapon_list GOBLIN_WEAPONS =
    { { WPN_DAGGER, 2 }, { NUM_WEAPONS, 1 } };
    static const vector<pair<brand_type, int>> GOBLIN_BRANDS =
    { { SPWPN_VENOM, 3 }, { NUM_SPECIAL_WEAPONS, 1 } };
    static const mon_weapon_spec GOBLIN_SPEC =
    { GOBLIN_WEAPONS, { 4, -1, 2, 2 }, GOBLIN_BRANDS, 3 };
    static const map<monster_type, mon_weapon_spec> primary_weapon_specs = {
        { MONS_GOBLIN, GOBLIN_SPEC },
    };
    static const map<monster_type, mon_weapon_spec> secondary_weapon_specs = {
        { MONS_RAT, { { { WPN_CLUB, 1 } } } },
    };
    bool force_item = false;
}
`

func TestParseSourceResolvesAliasesAndPreservesSourceOrder(t *testing.T) {
	primary, secondary, err := parseSource("mon-gear.cc", []byte(fixture))

	if err != nil {
		t.Fatal(err)
	}

	if len(primary) != 1 || len(secondary) != 1 {
		t.Fatalf("table sizes = %d, %d", len(primary), len(secondary))
	}

	goblin := primary[0]

	if goblin.MonsterID != "MONS_GOBLIN" ||
		goblin.SourceLine != 10 ||
		goblin.SpecLine != 8 ||
		goblin.WeaponListLine != 4 ||
		goblin.BrandListLine != 6 ||
		goblin.Weapons[0].ID != "WPN_DAGGER" ||
		goblin.Weapons[0].Weight != 2 ||
		goblin.Weapons[1].ID != "NUM_WEAPONS" ||
		goblin.Brands[0].ID != "SPWPN_VENOM" ||
		goblin.Plus.Min != -1 ||
		goblin.Plus.Rolls != 2 ||
		goblin.GoodChance != 3 {
		t.Fatalf("alias resolution lost source data: %+v", goblin)
	}

	if secondary[0].MonsterID != "MONS_RAT" ||
		secondary[0].Weapons[0].ID != "WPN_CLUB" {
		t.Fatalf("secondary table lost source data: %+v", secondary[0])
	}
}

func TestParseSourceRejectsUnsupportedOrIncompleteInput(t *testing.T) {
	cases := []struct {
		name string
		text string
	}{
		{
			name: "unknown alias",
			text: strings.Replace(fixture, "MONS_GOBLIN, GOBLIN_SPEC", "MONS_GOBLIN, MISSING_SPEC", 1),
		},

		{
			name: "unsupported expression",
			text: strings.Replace(fixture, "WPN_DAGGER, 2", "WPN_DAGGER, 1 + 1", 1),
		},

		{
			name: "unsupported tail",
			text: strings.Replace(
				fixture,
				"{ { WPN_DAGGER, 2 }, { NUM_WEAPONS, 1 } };",
				"{ { WPN_DAGGER, 2 }, { NUM_WEAPONS, 1 } } + other;",
				1,
			),
		},

		{
			name: "missing secondary table",
			text: strings.Replace(fixture, "secondary_weapon_specs", "other_weapon_specs", 1),
		},
	}

	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			if _, _, err := parseSource("mon-gear.cc", []byte(test.text)); err == nil {
				t.Fatal("unsupported source accepted")
			}
		})
	}
}
