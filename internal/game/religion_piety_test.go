package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// Source piety uses bounded random draws during rounding and upper taper.
// Save and restore must replay those draws and the resulting ECS state.
func TestReligionPietyRandomStateSurvivesRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/religion-piety-probe")

	if err != nil {
		t.Fatal(err)
	}

	game, err := NewDungeonGameWithRules(
		73,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	_, err = game.scripts.Policy("test.religion_piety", map[string]any{
		"god_id": "GOD_TROG",
		"piety":  int64(99),
	})

	if err != nil {
		t.Fatal(err)
	}

	if err := game.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("worship setup changed across restore")
	}

	for _, run := range []*Game{
		game,
		restored,
	} {
		_, err := run.scripts.Policy("test.religion_piety", map[string]any{
			"numerator":   int64(13),
			"denominator": int64(2),
		})

		if err != nil {
			t.Fatal(err)
		}

		if err := run.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}
	}

	after := game.Snapshot()

	if reflect.DeepEqual(before.RNG, after.RNG) {
		t.Fatal("piety gain did not consume its named random stream")
	}

	if !reflect.DeepEqual(after, restored.Snapshot()) {
		t.Fatal("restored piety or RNG diverged after identical gain")
	}
}
