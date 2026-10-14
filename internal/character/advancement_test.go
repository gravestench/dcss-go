package character

import (
	"testing"

	"dcrawl-go/internal/content"
)

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

		got, err := HumanExperienceNeeded(level)

		if err != nil || got != want {
			t.Fatalf("XL%d threshold = %d, %v; want %d", level, got, err, want)
		}

		atLevel, err := HumanLevelForExperience(got)

		if err != nil || atLevel != level {
			t.Fatalf("XP %d yields XL%d, %v; want XL%d", got, atLevel, err, level)
		}

		if level > 1 {
			below, err := HumanLevelForExperience(got - 1)

			if err != nil || below != level-1 {
				t.Fatalf("XP %d yields XL%d, %v; want XL%d", got-1, below, err, level-1)
			}
		}
	}

	for _, level := range []int{0, 28} {
		if _, err := HumanExperienceNeeded(level); err == nil {
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

	if hp, err := HumanMaxHP(1, species, profile.Skills); err != nil ||
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

		if err != nil || mp != tc.mp {
			t.Fatalf("XL%d MP = %d, %v; want %d", tc.level, mp, err, tc.mp)
		}
	}

	if hp, err := HumanMaxHP(2, species, profile.Skills); err != nil ||
		hp <= profile.MaxHP {
		t.Fatalf("XL2 HP = %d, %v; want more than %d", hp, err, profile.MaxHP)
	}

	if progress, err := HumanLevelProgress(9, 2); err != nil || progress != 0 {
		t.Fatalf("XL2 start progress = %d, %v", progress, err)
	}

	if progress, err := HumanLevelProgress(19, 2); err != nil || progress != 50 {
		t.Fatalf("XL2 midpoint progress = %d, %v", progress, err)
	}

	if progress, err := HumanLevelProgress(29, 2); err != nil || progress != 100 {
		t.Fatalf("pending XL3 progress = %d, %v", progress, err)
	}

	if progress, err := HumanLevelProgress(1059324, 27); err != nil ||
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
