package character

import (
	"testing"

	"dcrawl-go/internal/content"
)

func TestSpeciesExperienceThresholdsMatchPinnedSource(t *testing.T) {
	// player.cc:3355-3436 and skills.cc:2043-2049, evaluated with
	// the source's float return and integer truncation.
	tests := []struct {
		xpApt int
		want  [5]int
	}{
		{
			xpApt: -2,
			want: [5]int{
				15,
				48,
				6574,
				45230,
				1781563,
			},
		},

		{
			xpApt: -1,
			want: [5]int{
				12,
				41,
				5528,
				38033,
				1498110,
			},
		},

		{
			xpApt: 0,
			want: [5]int{
				10,
				34,
				4648,
				31982,
				1259755,
			},
		},

		{
			xpApt: 1,
			want: [5]int{
				9,
				29,
				3909,
				26894,
				1059324,
			},
		},

		{
			xpApt: 2,
			want: [5]int{
				7,
				24,
				3287,
				22615,
				890781,
			},
		},
	}

	levels := [5]int{
		2,
		3,
		10,
		13,
		27,
	}

	for _, test := range tests {
		for index, level := range levels {
			got, err := ExperienceNeeded(level, test.xpApt)

			if err != nil ||
				got != test.want[index] {
				t.Fatalf("aptitude %d XL%d needs %d XP, %v; want %d",
					test.xpApt, level, got, err, test.want[index])
			}
		}
	}
}

func TestBaseMaxHPUsesSpeciesModifierAndFightingAptitude(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	tengu, err := catalog.Species("SP_TENGU")

	if err != nil {
		t.Fatal(err)
	}

	fighting := []Skill{
		{
			ID:     "SK_FIGHTING",
			Level:  3,
			Points: 301,
		},
	}

	if hp, err := BaseMaxHP(1, tengu, fighting); err != nil ||
		hp != 14 {
		t.Fatalf("Tengu base HP = %d, %v; want 14", hp, err)
	}

	barachi, err := catalog.Species("SP_BARACHI")

	if err != nil {
		t.Fatal(err)
	}

	if hp, err := BaseMaxHP(20, barachi, fighting); err != nil ||
		hp != 128 {
		t.Fatalf("Barachi HP with +2 Fighting = %d, %v; want 128", hp, err)
	}
}

func TestSpeciesExperienceBoundaryAndHeldProgress(t *testing.T) {
	for _, test := range []struct {
		xp    int
		level int
	}{
		{
			xp:    9,
			level: 1,
		},

		{
			xp:    10,
			level: 2,
		},

		{
			xp:    33,
			level: 2,
		},

		{
			xp:    34,
			level: 3,
		},
	} {
		got, err := LevelForExperience(test.xp, 0)

		if err != nil ||
			got != test.level {
			t.Fatalf("Tengu XP %d gives XL%d, %v; want XL%d",
				test.xp, got, err, test.level)
		}
	}

	for _, test := range []struct {
		xp      int
		percent int
	}{
		{
			xp:      10,
			percent: 0,
		},

		{
			xp:      22,
			percent: 50,
		},

		{
			xp:      34,
			percent: 100,
		},
	} {
		got, err := LevelProgress(test.xp, 2, 0)

		if err != nil ||
			got != test.percent {
			t.Fatalf("held Tengu XL2 at XP %d = %d%%, %v; want %d%%",
				test.xp, got, err, test.percent)
		}
	}

	got, err := LevelProgress(1259755, 27, 0)

	if err != nil ||
		got != 0 {
		t.Fatalf("final Tengu level progress = %d, %v", got, err)
	}

	if _, err := LevelForExperience(-1, 0); err == nil {
		t.Fatal("accepted negative earned experience")
	}

	if _, err := LevelProgress(0, 2, 0); err == nil {
		t.Fatal("accepted an applied level without enough experience")
	}

	for _, aptitude := range []int{-1000, 1000} {
		if _, err := ExperienceNeeded(2, aptitude); err == nil {
			t.Fatalf("accepted overflowing or underflowing aptitude %d", aptitude)
		}
	}
}

func TestHumanExperienceThresholdsMatchSourceTable(t *testing.T) {
	// player.cc:exp_needed lists these values before Human's final minus one.
	source := []int{
		0,
		10,
		30,
		70,
		140,
		270,
		520,
		1010,
		1980,
		3910,
		7760,
		15450,
		26895,
		45585,
		72745,
		108375,
		152475,
		205045,
		266085,
		335595,
		413575,
		500025,
		594945,
		698335,
		810195,
		930525,
		1059325,
	}

	for index, tableValue := range source {
		level := index + 1
		want := tableValue - 1

		if level == 1 {
			want = 0
		}

		got, err := ExperienceNeeded(level, 1)

		if err != nil ||
			got != want {
			t.Fatalf("XL%d threshold = %d, %v; want %d", level, got, err, want)
		}

		atLevel, err := LevelForExperience(got, 1)

		if err != nil ||
			atLevel != level {
			t.Fatalf("XP %d yields XL%d, %v; want XL%d", got, atLevel, err, level)
		}

		if level > 1 {
			below, err := LevelForExperience(got-1, 1)

			if err != nil ||
				below != level-1 {
				t.Fatalf("XP %d yields XL%d, %v; want XL%d", got-1, below, err, level-1)
			}
		}
	}

	for _, level := range []int{0, 28} {
		if _, err := ExperienceNeeded(level, 1); err == nil {
			t.Fatalf("accepted XL%d", level)
		}
	}
}

func TestHumanExperienceProgressAndVitalGrowth(t *testing.T) {
	catalog, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	profile, err := BuildStartProfile(catalog, "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER")

	if err != nil {
		t.Fatal(err)
	}

	species, _ := catalog.Species("SP_HUMAN")

	if hp, err := BaseMaxHP(1, species, profile.Skills); err != nil ||
		hp != profile.MaxHP {
		t.Fatalf("XL1 HP = %d, %v; want %d", hp, err, profile.MaxHP)
	}

	for _, tc := range []struct {
		level int
		mp    int
	}{
		{
			level: 1,
			mp:    1,
		},

		{
			level: 2,
			mp:    2,
		},

		{
			level: 23,
			mp:    23,
		},

		{
			level: 27,
			mp:    23,
		},
	} {
		mp, err := HumanMaxMP(tc.level, species)

		if err != nil ||
			mp != tc.mp {
			t.Fatalf("XL%d MP = %d, %v; want %d", tc.level, mp, err, tc.mp)
		}
	}

	if hp, err := BaseMaxHP(2, species, profile.Skills); err != nil ||
		hp <= profile.MaxHP {
		t.Fatalf("XL2 HP = %d, %v; want more than %d", hp, err, profile.MaxHP)
	}

	if progress, err := LevelProgress(9, 2, 1); err != nil ||
		progress != 0 {
		t.Fatalf("XL2 start progress = %d, %v", progress, err)
	}

	if progress, err := LevelProgress(19, 2, 1); err != nil ||
		progress != 50 {
		t.Fatalf("XL2 midpoint progress = %d, %v", progress, err)
	}

	if progress, err := LevelProgress(29, 2, 1); err != nil ||
		progress != 100 {
		t.Fatalf("pending XL3 progress = %d, %v", progress, err)
	}

	if progress, err := LevelProgress(1059324, 27, 1); err != nil ||
		progress != 0 {
		t.Fatalf("final XL progress = %d, %v", progress, err)
	}

	for _, level := range []int{
		3,
		9,
		15,
		21,
		27,
	} {
		if !HumanNeedsManualStat(level) {
			t.Fatalf("XL%d did not request its source stat choice", level)
		}
	}
}
