package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// A modded Xom effect can fail during another command. The command owns
// ECS, level, event, time, and RNG rollback as one transaction.
func TestXomActionFailureRollsBackPlayerTurn(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-failure")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		901,
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

	defer g.Close()

	before := g.Snapshot()
	_, err = g.Step(Command{Kind: CommandWait})

	if err == nil {
		t.Fatal("broken Xom mod effect succeeded")
	}

	if !strings.Contains(err.Error(), "broken Xom mod effect") {
		t.Fatalf("failed Xom action returned %v", err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("failed Xom action committed part of the turn")
	}
}
