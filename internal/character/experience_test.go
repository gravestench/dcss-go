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
		got, err := RatKillExperience(rat, hp)
		if err != nil || got != 1 {
			t.Fatalf("rat with %d HP XP = %d, %v; want 1", hp, got, err)
		}
	}
}

func TestHumanFirstLevelProgressUsesNineXPThreshold(t *testing.T) {
	for _, tc := range []struct{ xp, percent int }{{0, 0}, {1, 11}, {4, 44}, {8, 88}} {
		got, err := HumanFirstLevelProgress(tc.xp)
		if err != nil || got != tc.percent {
			t.Fatalf("XP %d => %d%%, %v; want %d%%", tc.xp, got, err, tc.percent)
		}
	}
	for _, xp := range []int{-1, 9} {
		if _, err := HumanFirstLevelProgress(xp); err == nil {
			t.Fatalf("accepted unsupported XP %d", xp)
		}
	}
}

func TestRatExperienceRejectsWrongKindAndHP(t *testing.T) {
	for _, tc := range []struct {
		rat content.MonsterDef
		hp  int
	}{
		{content.MonsterDef{ID: "MONS_ORC", HD: 1, Speed: 10, XPModifier: 1}, 4},
		{content.MonsterDef{ID: "MONS_RAT", HD: 1, Speed: 10, XPModifier: 1}, 0},
		{content.MonsterDef{ID: "MONS_RAT", HD: 2, Speed: 10, XPModifier: 1}, 4},
	} {
		if _, err := RatKillExperience(tc.rat, tc.hp); err == nil {
			t.Fatalf("accepted rat %+v with HP %d", tc.rat, tc.hp)
		}
	}
}
