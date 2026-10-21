package game

import (
	"reflect"
	"slices"
	"testing"
)

// A scheduled Orc descent reaches a source ending on Orc:2. The selected
// primary and its child maps remain fixed across a Go save and restore.
func TestOrcEndVaultAppearsOnTravel(t *testing.T) {
	g := newGeneratedTestGame(t, 425)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_ORC" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	if parentDepth == 0 {
		t.Fatal("scheduled run has no Orc entrance")
	}

	descendGeneratedTo(t, g, parentDepth)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	orc := followBranch(t, g, g.levels[parentDepth], "BRANCH_ORC")
	end := descendBranch(t, g, orc, 2)
	ids := end.VaultIDs()

	if end.BranchID != "BRANCH_ORC" || end.LocalDepth != 2 ||
		end.VaultID() == "" || !slices.Contains(ids, end.VaultID()) {
		t.Fatalf("Orc ending = %s:%d primary %q history %v",
			end.BranchID, end.LocalDepth, end.VaultID(), ids)
	}

	// The enlarged travel-only health is not a legal saved character.
	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore Orc:2: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Orc:2 ending changed across restore")
	}
}
