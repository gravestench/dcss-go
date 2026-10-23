package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// The death phase must inspect a credited actor before deleting it. Trog's
// response message proves the source kill conduct reached the player rule.
func TestReligionKillConductRunsInDeathPhase(t *testing.T) {
	rules, err := modfs.Load("testdata/religion-conduct-probe")

	if err != nil {
		t.Fatal(err)
	}

	game, err := newScenarioWithRules(
		811,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	worship, found := game.scripts.Components()["religion.worship"].Get(
		game.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	if err := worship.Set("god_id", "GOD_TROG"); err != nil {
		t.Fatal(err)
	}

	result, err := game.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	responded := false

	for _, event := range result.Events {
		if event.Kind == "religion" &&
			strings.Contains(event.Text, "Trog accepts your kill") {
			responded = true
		}
	}

	if !responded {
		t.Fatalf("credited death omitted Trog conduct: %+v", result.Events)
	}

	before := game.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("religion conduct state or RNG changed on restore")
	}
}

// A real successful player spell must reach Trog's conduct after its Lua
// effect, using the same worship component the terminal and saves read.
func TestReligionSpellConductRunsFromCast(t *testing.T) {
	game, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_CONJURER",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	worship, found := game.scripts.Components()["religion.worship"].Get(
		game.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	if err := worship.Set("god_id", "GOD_TROG"); err != nil {
		t.Fatal(err)
	}

	if err := worship.Set("piety", int64(50)); err != nil {
		t.Fatal(err)
	}

	result, err := game.Step(Command{
		Kind:    CommandForceCast,
		SpellID: "SPELL_MAGIC_DART",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	worship, found = game.scripts.Components()["religion.worship"].Get(
		game.player)

	if !found {
		t.Fatal("cast removed worship state")
	}

	buffer, err := worship.Get("piety_hysteresis")

	if err != nil {
		t.Fatal(err)
	}

	if buffer != int64(1) {
		t.Fatalf("successful cast omitted Trog offense: buffer=%v err=%v events=%+v",
			buffer, err, result.Events)
	}
}

// One real player-sourced hit contributes to Uskayaw's saved pool. The
// reaction awards it after damage, then save/restore preserves the result.
func TestReligionUskayawDamageResolvesAfterTurn(t *testing.T) {
	rules, err := modfs.Load("testdata/religion-uskayaw-probe")

	if err != nil {
		t.Fatal(err)
	}

	game, err := newScenarioWithRules(
		813,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	worship, found := game.scripts.Components()["religion.worship"].Get(
		game.player)

	if !found {
		t.Fatal("player lacks worship state")
	}

	if err := worship.Set("god_id", "GOD_USKAYAW"); err != nil {
		t.Fatal(err)
	}

	if err := worship.Set("piety", int64(30)); err != nil {
		t.Fatal(err)
	}

	if _, err := game.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	worship, found = game.scripts.Components()["religion.worship"].Get(
		game.player)

	if !found {
		t.Fatal("hit removed worship state")
	}

	points, err := worship.Get("piety")

	if err != nil {
		t.Fatal(err)
	}

	if points.(int64) <= 30 {
		t.Fatalf("Uskayaw reaction omitted hit piety: %v, %v", points, err)
	}

	before := game.Snapshot()
	restored, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(before, restored.Snapshot()) {
		t.Fatal("Uskayaw momentum changed on restore")
	}
}
