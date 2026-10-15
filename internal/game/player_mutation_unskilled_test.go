package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestUnskilledReassessesAndRestoresCharacter(t *testing.T) {
	rules, err := modfs.Load("testdata/mutation-integration")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		43,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	before := g.View()
	result, err := g.scripts.Policy("test.grant_unskilled", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["kind"] != "granted" {
		t.Fatalf("Unskilled grant = %+v", result)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	after := g.View()
	changed := false

	for index, skill := range after.Skills {
		if skill.Level < before.Skills[index].Level {
			changed = true
		}
	}

	if !changed {
		t.Fatalf("Unskilled did not reassess %+v", after.Skills)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(loaded.View().Skills, after.Skills) ||
		loaded.View().PlayerMaxHP != after.PlayerMaxHP ||
		loaded.View().PlayerMaxMP != after.PlayerMaxMP {
		t.Fatal("restored Unskilled character changed derived state")
	}
}
