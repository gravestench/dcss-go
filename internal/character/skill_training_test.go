package character

import "testing"

func TestHumanSkillPointThresholds(t *testing.T) {
	tests := []struct {
		level int
		want  int
	}{
		{
			level: 0,
			want:  0,
		},

		{
			level: 1,
			want:  50,
		},

		{
			level: 2,
			want:  150,
		},

		{
			level: 3,
			want:  300,
		},

		{
			level: 9,
			want:  2250,
		},

		{
			level: 10,
			want:  2775,
		},

		{
			level: 18,
			want:  9675,
		},

		{
			level: 19,
			want:  10900,
		},

		{
			level: 26,
			want:  22275,
		},

		{
			level: 27,
			want:  24325,
		},
	}

	for _, test := range tests {
		got, err := HumanSkillPointsNeeded(test.level)

		if err != nil || got != test.want {
			t.Fatalf("level %d needs %d, want %d: %v", test.level, got, test.want, err)
		}
	}

	for _, level := range []int{-1, 28} {
		if _, err := HumanSkillPointsNeeded(level); err == nil {
			t.Fatalf("accepted skill level %d", level)
		}
	}
}

func TestHumanSkillLevelFromPoints(t *testing.T) {
	tests := []struct {
		points int
		want   int
	}{
		{
			points: 0,
			want:   0,
		},

		{
			points: 49,
			want:   0,
		},

		{
			points: 50,
			want:   1,
		},

		{
			points: 150,
			want:   2,
		},

		{
			points: 300,
			want:   3,
		},

		{
			points: 2775,
			want:   10,
		},

		{
			points: 24325,
			want:   27,
		},

		{
			points: 30000,
			want:   27,
		},
	}

	for _, test := range tests {
		got, err := HumanSkillLevel(test.points)

		if err != nil || got != test.want {
			t.Fatalf("%d points gives level %d, want %d: %v", test.points, got, test.want, err)
		}
	}

	if _, err := HumanSkillLevel(-1); err == nil {
		t.Fatal("accepted negative skill points")
	}
}

func TestSkillCostBoundaries(t *testing.T) {
	for _, test := range []struct {
		spent int
		level int
		cost  int
	}{
		{
			spent: 0,
			level: 1,
			cost:  1,
		},

		{
			spent: 116,
			level: 1,
			cost:  1,
		},

		{
			spent: 117,
			level: 2,
			cost:  2,
		},

		{
			spent: 376,
			level: 2,
			cost:  2,
		},

		{
			spent: 377,
			level: 3,
			cost:  3,
		},
	} {
		level, err := SkillCostLevel(test.spent)

		if err != nil || level != test.level {
			t.Fatalf("spent %d gives cost level %d, want %d: %v", test.spent, level, test.level, err)
		}

		cost, err := SkillPointCost(level)

		if err != nil || cost != test.cost {
			t.Fatalf("cost level %d costs %d, want %d: %v", level, cost, test.cost, err)
		}
	}

	if cost, err := SkillPointCost(27); err != nil || cost != 265 {
		t.Fatalf("cost level 27 costs %d, want 265: %v", cost, err)
	}

	if _, err := SkillCostLevel(-1); err == nil {
		t.Fatal("accepted negative spent experience")
	}

	for _, level := range []int{0, 28} {
		if _, err := SkillPointCost(level); err == nil {
			t.Fatalf("accepted cost level %d", level)
		}
	}
}
