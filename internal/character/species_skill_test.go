package character

import "testing"

func TestSpeciesSkillThresholdsMatchPinnedSource(t *testing.T) {
	// skills.cc:2043-2084 uses a float aptitude factor and truncates the
	// product to unsigned integer. These values came from a standalone C++
	// evaluation of the pinned source formula.
	tests := []struct {
		aptitude int
		want     [8]int
	}{
		{
			aptitude: -5,
			want: [8]int{
				118,
				713,
				5351,
				6600,
				23011,
				25924,
				52979,
				57854,
			},
		},

		{
			aptitude: -2,
			want: [8]int{
				70,
				424,
				3181,
				3924,
				13682,
				15414,
				31501,
				34400,
			},
		},

		{
			aptitude: 0,
			want: [8]int{
				50,
				300,
				2250,
				2775,
				9675,
				10900,
				22275,
				24325,
			},
		},

		{
			aptitude: 2,
			want: [8]int{
				35,
				212,
				1590,
				1962,
				6841,
				7707,
				15750,
				17200,
			},
		},

		{
			aptitude: 9,
			want: [8]int{
				10,
				63,
				473,
				583,
				2033,
				2291,
				4682,
				5113,
			},
		},
	}

	levels := [8]int{
		1,
		3,
		9,
		10,
		18,
		19,
		26,
		27,
	}

	for _, test := range tests {
		for index, level := range levels {
			got, err := SkillPointsNeeded(level, test.aptitude)

			if err != nil ||
				got != test.want[index] {
				t.Fatalf("aptitude %d level %d needs %d, %v; want %d",
					test.aptitude, level, got, err, test.want[index])
			}
		}
	}
}

func TestSpeciesSkillLevelUsesSelectedAptitude(t *testing.T) {
	for _, test := range []struct {
		points   int
		aptitude int
		want     int
	}{
		{
			points:   50,
			aptitude: 0,
			want:     1,
		},

		{
			points:   50,
			aptitude: -2,
			want:     0,
		},

		{
			points:   50,
			aptitude: 2,
			want:     1,
		},
	} {
		got, err := SkillLevel(test.points, test.aptitude)

		if err != nil ||
			got != test.want {
			t.Fatalf("%d points at aptitude %d = level %d, %v; want %d",
				test.points, test.aptitude, got, err, test.want)
		}
	}
}

func TestSpeciesSkillThresholdsRejectInvalidInputs(t *testing.T) {
	for _, level := range []int{-1, 28} {
		if _, err := SkillPointsNeeded(level, 0); err == nil {
			t.Fatalf("accepted skill level %d", level)
		}
	}

	for _, aptitude := range []int{-1000, 1000} {
		if _, err := SkillPointsNeeded(1, aptitude); err == nil {
			t.Fatalf("accepted invalid skill aptitude %d", aptitude)
		}
	}

	if _, err := SkillLevel(-1, 0); err == nil {
		t.Fatal("accepted negative skill points")
	}

	if _, err := ScaledSkill(Skill{
		ID:    "SK_FIGHTING",
		Level: 27,
	}, 10, 1000); err == nil {
		t.Fatal("final skill level skipped aptitude validation")
	}
}
