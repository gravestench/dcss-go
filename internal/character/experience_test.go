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
		got, err := OrdinaryAnimalExperience(rat, hp)

		if err != nil || got != 1 {
			t.Fatalf("rat with %d HP XP = %d, %v; want 1", hp, got, err)
		}
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
		got, err := OrdinaryAnimalExperience(quokka, hp)
		want := 2

		if hp == 3 {
			want = 1
		}

		if err != nil || got != want {
			t.Fatalf("quokka max HP %d gives %d XP, %v; want %d", hp, got, err, want)
		}
	}

	for _, hp := range []int{2, 9} {
		if _, err := OrdinaryAnimalExperience(quokka, hp); err == nil {
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
		got, err := OrdinaryAnimalExperience(lizard, hp)

		if err != nil || got != 1 {
			t.Fatalf("frilled lizard at %d HP gives %d XP, %v; want 1", hp, got, err)
		}
	}

	if _, err := OrdinaryAnimalExperience(lizard, 4); err == nil {
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
			got, err := OrdinaryAnimalExperience(definition, hp)

			if err != nil {
				t.Fatalf("%s at %d HP: %v", tc.id, hp, err)
			}

			if hp == tc.atHP && got != tc.wantXP {
				t.Fatalf("%s at %d HP awards %d XP, want %d", tc.id, hp, got, tc.wantXP)
			}
		}

		for _, hp := range []int{tc.minHP - 1, tc.maxHP + 1} {
			if _, err := OrdinaryAnimalExperience(definition, hp); err == nil {
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
		got, err := OrdinaryAnimalExperience(jackal, hp)

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
		if _, err := OrdinaryAnimalExperience(jackal, hp); err == nil {
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
		got, err := HumanLevelProgress(tc.xp, 1)

		if err != nil || got != tc.percent {
			t.Fatalf("XP %d => %d%%, %v; want %d%%", tc.xp, got, err, tc.percent)
		}
	}

	for _, xp := range []int{-1} {
		if _, err := HumanLevelProgress(xp, 1); err == nil {
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
		if _, err := OrdinaryAnimalExperience(tc.rat, tc.hp); err == nil {
			t.Fatalf("accepted rat %+v with HP %d", tc.rat, tc.hp)
		}
	}
}
