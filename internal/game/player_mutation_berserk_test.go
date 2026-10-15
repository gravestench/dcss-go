package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func chooseBerserkStream(t *testing.T, g *Game) {
	t.Helper()

	for state := uint64(0); state < 100000; state++ {
		probe := RestoreRNGStreams(g.seed, map[string]uint64{
			"mutation": state,
		})

		roll, err := probe.Intn("mutation", 100)

		if err != nil {
			t.Fatal(err)
		}

		if roll == 0 {
			g.rng.states["mutation"] = state

			return
		}
	}

	t.Fatal("could not choose a berserk trigger stream")
}

func TestBerserkRejectsNoncombatCommandsWithoutTime(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["character.rage"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(100),
		},
	); err != nil {
		t.Fatal(err)
	}

	for _, command := range []Command{
		{Kind: CommandQuaff},
		{Kind: CommandWear},
		{Kind: CommandTakeOff},
		{Kind: CommandFire},
		{Kind: CommandThrow},
		{Kind: CommandMemorise},
		{Kind: CommandCast},
		{Kind: CommandForceCast},
	} {
		result, err := g.Step(command)

		if err != nil {
			t.Fatalf("command %d: %v", command.Kind, err)
		}

		if result.Spent != 0 ||
			len(result.Events) == 0 ||
			!strings.Contains(result.Events[0].Text, "too berserk") {
			t.Fatalf("command %d spent %d aut: %+v",
				command.Kind, result.Spent, result.Events)
		}
	}
}

func TestBerserkMutationStartsRageBeforeMeleeAndRestores(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_BERSERK")
	chooseBerserkStream(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	before, _ := g.stores.Health.Get(g.player)
	beforeMax := before.Max
	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 ||
		!g.scripts.Components()["character.rage"].Has(g.player) {
		t.Fatal("melee attempt did not start a saved rage")
	}

	after, _ := g.stores.Health.Get(g.player)

	if after.Max != beforeMax*3/2 {
		t.Fatalf("berserk HP maximum = %d, want %d", after.Max,
			beforeMax*3/2)
	}

	timing, err := g.scripts.Policy("command.timing", map[string]any{
		"attack_target": false,
		"intent_kind":   int(ecs.IntentWait),
		"item_id":       uint64(0),
	})

	if err != nil {
		t.Fatal(err)
	}

	if cost := timing["cost"].(int64); cost >= 10 {
		t.Fatalf("berserk action cost = %d, want haste", cost)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["character.rage"].Has(restored.player) {
		t.Fatal("restore lost rage duration")
	}

	if _, err := restored.scripts.Components()["character.rage"].Set(
		restored.player,
		map[string]any{
			"remaining_aut":      int64(1),
			"cooldown_aut":       int64(0),
			"noncombat_actions":  int64(0),
			"attacked_this_turn": false,
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	ended, _ := restored.stores.Health.Get(restored.player)

	if ended.Max != beforeMax ||
		!restored.scripts.Components()["character.slow"].Has(restored.player) {
		t.Fatal("rage expiry did not restore HP and apply exhaustion slow")
	}

	state, found := restored.scripts.Components()["character.rage"].Get(
		restored.player)

	if !found {
		t.Fatal("rage cooldown vanished after exhaustion")
	}

	cooldown, err := state.Get("cooldown_aut")

	if err != nil ||
		cooldown.(int64) <= 0 {
		t.Fatalf("rage cooldown = %v, %v", cooldown, err)
	}
}

func TestRestoreRejectsInvalidRageState(t *testing.T) {
	g := newStepGame(t)

	if _, err := g.scripts.Components()["character.rage"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(-1),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := Restore(g.Snapshot()); err == nil {
		t.Fatal("restore accepted a negative rage duration")
	}
}
