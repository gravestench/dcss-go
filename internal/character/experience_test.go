package character

import (
	"testing"

	"dcrawl-go/internal/content"
)

func TestFixedRatGrantsOneSourceExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rat, err := catalog.Monster("MONS_RAT")

	if err != nil {
		t.Fatal(err)
	}

	for hp := 1; hp <= 4; hp++ {
		got, err := OrdinaryNaturalExperience(rat, hp)

		if err != nil ||
			got != 1 {
			t.Fatalf("rat with %d HP XP = %d, %v; want 1", hp, got, err)
		}
	}
}

func TestHobgoblinNaturalAttackAndEquipmentUseExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	hobgoblin, err := catalog.Monster("MONS_HOBGOBLIN")

	if err != nil {
		t.Fatal(err)
	}

	profile, found := OrdinaryNaturalProfileFor(hobgoblin.ID)

	if !found ||
		profile.MinHP != 3 ||
		profile.MaxHP != 8 ||
		profile.Damage != 5 ||
		profile.AttackTypeID != "AT_HIT" ||
		profile.ItemUseID != "MONUSE_WEAPONS_ARMOUR" {
		t.Fatalf("hobgoblin profile = %+v, found %v", profile, found)
	}

	for hp := profile.MinHP; hp <= profile.MaxHP; hp++ {
		if _, err := OrdinaryNaturalExperience(hobgoblin, hp); err != nil {
			t.Fatalf("hobgoblin with %d HP: %v", hp, err)
		}
	}
}

func TestGoblinAndKoboldSourceProfiles(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	for _, test := range []struct {
		monsterID    string
		averageHP10x int
		minHP        int
		maxHP        int
	}{
		{
			monsterID:    "MONS_GOBLIN",
			averageHP10x: 40,
			minHP:        2,
			maxHP:        6,
		},

		{
			monsterID:    "MONS_KOBOLD",
			averageHP10x: 35,
			minHP:        2,
			maxHP:        5,
		},
	} {
		definition, err := catalog.Monster(test.monsterID)

		if err != nil {
			t.Fatal(err)
		}

		profile, found := OrdinaryNaturalProfileFor(test.monsterID)

		if !found ||
			profile.HitDice != 1 ||
			profile.AverageHP10x != test.averageHP10x ||
			profile.MinHP != test.minHP ||
			profile.MaxHP != test.maxHP ||
			profile.Damage != 1 ||
			profile.Speed != 10 ||
			profile.AttackTypeID != "AT_HIT" ||
			profile.ItemUseID != "MONUSE_WEAPONS_ARMOUR" ||
			profile.XPModifier != 10 {
			t.Fatalf("%s profile = %+v, found %v", test.monsterID, profile, found)
		}

		for hp := test.minHP; hp <= test.maxHP; hp++ {
			if _, err := OrdinaryNaturalExperience(definition, hp); err != nil {
				t.Fatalf("%s with %d HP: %v", test.monsterID, hp, err)
			}
		}
	}
}

func TestBatPlainHitProfileAndSpeedExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	bat, err := catalog.Monster("MONS_BAT")

	if err != nil {
		t.Fatal(err)
	}

	profile, found := OrdinaryNaturalProfileFor(bat.ID)

	if !found ||
		profile.MinHP != 2 ||
		profile.MaxHP != 5 ||
		profile.Speed != 30 {
		t.Fatalf("bat profile = %+v, found %v", profile, found)
	}

	xp, err := OrdinaryNaturalExperience(bat, 4)

	if err != nil {
		t.Fatal(err)
	}

	if xp != 2 {
		t.Fatalf("bat with 4 HP grants %d XP, want 2", xp)
	}
}

func TestBallPythonProfileRequiresSourceGrabAttack(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	python, err := catalog.Monster("MONS_BALL_PYTHON")

	if err != nil {
		t.Fatal(err)
	}

	profile, found := OrdinaryNaturalProfileFor(python.ID)

	if !found ||
		profile.MinHP != 2 ||
		profile.MaxHP != 5 ||
		profile.Speed != 12 ||
		profile.ConstrictDamage != 1 {
		t.Fatalf("ball python profile %+v, found %v", profile, found)
	}

	if xp, err := OrdinaryNaturalExperience(python, 4); err != nil ||
		xp != 2 {
		t.Fatalf("ball python XP = %d, %v; want 2", xp, err)
	}

	python.Attacks[1].FlavourID = "AF_PLAIN"

	if _, err := OrdinaryNaturalExperience(python, 4); err == nil {
		t.Fatal("accepted a python without its source crush attack")
	}
}

func TestAdderPoisonBiteUsesActualMaximumHPForExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	adder, err := catalog.Monster("MONS_ADDER")

	if err != nil {
		t.Fatal(err)
	}

	profile, found := OrdinaryNaturalProfileFor(adder.ID)

	if !found ||
		!profile.Poison ||
		profile.MinHP != 7 || profile.MaxHP != 15 {
		t.Fatalf("adder combat profile %+v, present %v", profile, found)
	}

	for hp := profile.MinHP; hp <= profile.MaxHP; hp++ {
		if _, err := OrdinaryNaturalExperience(adder, hp); err != nil {
			t.Fatalf("adder with %d maximum HP: %v", hp, err)
		}
	}

	adder.Attacks[0].FlavourID = "AF_PLAIN"

	if _, err := OrdinaryNaturalExperience(adder, 11); err == nil {
		t.Fatal("accepted an adder without its source poison bite")
	}
}

func TestQuokkaOrdinaryExperienceUsesActualMaximumHP(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	quokka, err := catalog.Monster("MONS_QUOKKA")

	if err != nil {
		t.Fatal(err)
	}

	for hp := 3; hp <= 8; hp++ {
		got, err := OrdinaryNaturalExperience(quokka, hp)
		want := 2

		if hp == 3 {
			want = 1
		}

		if err != nil ||
			got != want {
			t.Fatalf("quokka max HP %d gives %d XP, %v; want %d", hp, got, err, want)
		}
	}

	for _, hp := range []int{2, 9} {
		if _, err := OrdinaryNaturalExperience(quokka, hp); err == nil {
			t.Fatalf("accepted unsupported quokka max HP %d", hp)
		}
	}
}

func TestFrilledLizardExperienceUsesSourceOrdinaryBite(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	lizard, err := catalog.Monster("MONS_FRILLED_LIZARD")

	if err != nil {
		t.Fatal(err)
	}

	for hp := 1; hp <= 3; hp++ {
		got, err := OrdinaryNaturalExperience(lizard, hp)

		if err != nil ||
			got != 1 {
			t.Fatalf("frilled lizard at %d HP gives %d XP, %v; want 1", hp, got, err)
		}
	}

	if _, err := OrdinaryNaturalExperience(lizard, 4); err == nil {
		t.Fatal("accepted impossible frilled-lizard maximum HP")
	}
}

func TestCockroachAndWormPlainBiteExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		id     string
		minHP  int
		maxHP  int
		atHP   int
		wantXP int
	}{
		{
			id:     "MONS_GIANT_COCKROACH",
			minHP:  3,
			maxHP:  7,
			atHP:   5,
			wantXP: 2,
		},

		{
			id:     "MONS_WORM",
			minHP:  12,
			maxHP:  24,
			atHP:   18,
			wantXP: 5,
		},
	} {
		definition, err := catalog.Monster(tc.id)

		if err != nil {
			t.Fatal(err)
		}

		for _, hp := range []int{
			tc.minHP,
			tc.atHP,
			tc.maxHP,
		} {
			got, err := OrdinaryNaturalExperience(definition, hp)

			if err != nil {
				t.Fatalf("%s at %d HP: %v", tc.id, hp, err)
			}

			if hp == tc.atHP && got != tc.wantXP {
				t.Fatalf("%s at %d HP awards %d XP, want %d", tc.id, hp, got, tc.wantXP)
			}
		}

		for _, hp := range []int{tc.minHP - 1, tc.maxHP + 1} {
			if _, err := OrdinaryNaturalExperience(definition, hp); err == nil {
				t.Fatalf("accepted impossible %s maximum HP %d", tc.id, hp)
			}
		}
	}
}

func TestJackalPlainBiteExperience(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	jackal, err := catalog.Monster("MONS_JACKAL")

	if err != nil {
		t.Fatal(err)
	}

	for hp := 3; hp <= 8; hp++ {
		got, err := OrdinaryNaturalExperience(jackal, hp)

		if err != nil {
			t.Fatalf("jackal at %d HP: %v", hp, err)
		}

		want := 2

		if hp == 3 {
			want = 1
		}

		if got != want {
			t.Fatalf("jackal at %d HP awards %d XP, want %d", hp, got, want)
		}
	}

	for _, hp := range []int{2, 9} {
		if _, err := OrdinaryNaturalExperience(jackal, hp); err == nil {
			t.Fatalf("accepted impossible jackal HP %d", hp)
		}
	}
}

func TestHumanFirstLevelProgressUsesNineXPThreshold(t *testing.T) {
	for _, tc := range []struct {
		xp      int
		percent int
	}{
		{
			xp:      0,
			percent: 0,
		},

		{
			xp:      1,
			percent: 11,
		},

		{
			xp:      4,
			percent: 44,
		},

		{
			xp:      8,
			percent: 88,
		},
	} {
		got, err := LevelProgress(tc.xp, 1, 1)

		if err != nil ||
			got != tc.percent {
			t.Fatalf("XP %d => %d%%, %v; want %d%%", tc.xp, got, err, tc.percent)
		}
	}

	for _, xp := range []int{-1} {
		if _, err := LevelProgress(xp, 1, 1); err == nil {
			t.Fatalf("accepted unsupported XP %d", xp)
		}
	}
}

func TestRatExperienceRejectsWrongKindAndHP(t *testing.T) {
	for _, tc := range []struct {
		rat content.MonsterDef
		hp  int
	}{
		{
			rat: content.MonsterDef{
				ID:         "MONS_ORC",
				HD:         1,
				Speed:      10,
				XPModifier: 1,
			},
			hp: 4,
		},

		{
			rat: content.MonsterDef{
				ID:         "MONS_RAT",
				HD:         1,
				Speed:      10,
				XPModifier: 1,
			},
			hp: 0,
		},

		{
			rat: content.MonsterDef{
				ID:         "MONS_RAT",
				HD:         2,
				Speed:      10,
				XPModifier: 1,
			},
			hp: 4,
		},
	} {
		if _, err := OrdinaryNaturalExperience(tc.rat, tc.hp); err == nil {
			t.Fatalf("accepted rat %+v with HP %d", tc.rat, tc.hp)
		}
	}
}
