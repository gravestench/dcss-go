package game

import "testing"

func TestSpellFailureMathMatchesPinnedSourceVectors(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIRE_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	cases := []struct {
		name       string
		power      int
		intellect  int
		penalty    int
		level      int
		wantRaw    int64
		wantChance int64
	}{
		{
			name:       "untrained first level",
			intellect:  10,
			level:      1,
			wantRaw:    44,
			wantChance: 36,
		},

		{
			name:       "untrained third level",
			intellect:  10,
			level:      3,
			wantRaw:    62,
			wantChance: 75,
		},

		{
			name:       "high school skill",
			power:      90,
			intellect:  15,
			level:      1,
			wantRaw:    14,
			wantChance: 1,
		},

		{
			name:       "armour penalty caps failure",
			intellect:  10,
			penalty:    30,
			level:      5,
			wantRaw:    100,
			wantChance: 100,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			result, policyErr := g.scripts.Policy(
				"magic.failure_formula",
				map[string]any{
					"power6":         tc.power,
					"intelligence":   tc.intellect,
					"armour_penalty": tc.penalty,
					"spell_level":    tc.level,
				},
			)

			if policyErr != nil {
				t.Fatal(policyErr)
			}

			if result["raw"] != tc.wantRaw ||
				result["percent"] != tc.wantChance {
				t.Fatalf("failure profile = %v", result)
			}
		})
	}
}

func TestHumanConjurerSpellPowerMatchesPinnedSource(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy("magic.spell_power", map[string]any{
		"spell_id": "SPELL_MAGIC_DART",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result["failure_power6"] != int64(53) ||
		result["cast_power"] != int64(15) {
		t.Fatalf("Magic Dart power = %v, want 53 failure and 15 cast", result)
	}
}

func TestFighterArmourSpellPenaltyMatchesPinnedSource(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy("magic.armour_penalty", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["penalty"] != int64(45) {
		t.Fatalf("Fighter armour spell penalty = %v, want 45", result)
	}
}

func TestConjurerMagicDartFailureProfileMatchesPinnedSource(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	result, err := g.scripts.Policy("magic.spell_failure", map[string]any{
		"spell_id": "SPELL_MAGIC_DART",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result["raw"] != int64(20) ||
		result["percent"] != int64(3) {
		t.Fatalf("Magic Dart failure profile = %v, want 20 raw and 3%%", result)
	}
}

func TestSpellRangeUsesSourceBoundsAndVisionCap(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	cases := []struct {
		spellID string
		want    int64
	}{
		{
			spellID: "SPELL_FREEZE",
			want:    1,
		},
		{
			spellID: "SPELL_MAGIC_DART",
			want:    7,
		},
		{
			spellID: "SPELL_LIGHTNING_BOLT",
			want:    4,
		},
	}

	for _, tc := range cases {
		result, policyErr := g.scripts.Policy(
			"magic.spell_range",
			map[string]any{"spell_id": tc.spellID},
		)

		if policyErr != nil {
			t.Fatal(policyErr)
		}

		if result["range"] != tc.want {
			t.Fatalf("%s range = %v, want %d", tc.spellID,
				result["range"], tc.want)
		}
	}
}
