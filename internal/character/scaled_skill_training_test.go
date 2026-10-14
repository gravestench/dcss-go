package character

import "testing"

func TestScaledHumanSkillAcrossTrainingBreakpoints(t *testing.T) {
	threshold, err := SkillPointsNeeded(10, 0)

	if err != nil {
		t.Fatal(err)
	}

	skill := Skill{
		ID:     "SK_FIGHTING",
		Level:  9,
		Points: threshold - 1,
	}

	got, err := ScaledSkill(skill, 100, 0)

	if err != nil ||
		got != 999 {
		t.Fatalf("level nine just below threshold = %d, want 999", got)
	}

	skill.Level = 10
	skill.Points = threshold

	got, err = ScaledSkill(skill, 100, 0)

	if err != nil ||
		got != 1000 {
		t.Fatalf("level ten at threshold = %d, want 1000", got)
	}

	skill.Level = 27
	skill.Points, err = SkillPointsNeeded(27, 0)

	if err != nil {
		t.Fatal(err)
	}

	got, err = ScaledSkill(skill, 100, 0)

	if err != nil ||
		got != 2700 {
		t.Fatalf("final skill level = %d, want 2700", got)
	}
}
