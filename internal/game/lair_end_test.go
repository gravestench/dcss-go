package game

import (
	"reflect"
	"slices"
	"testing"
)

// A scheduled Lair descent reaches the authored fifth-floor ending. Its
// primary and any paired small ending remain the same after a Go save cycle.
func TestLairEndVaultAppearsOnTravel(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	if parentDepth == 0 {
		t.Fatal("scheduled run has no Lair entrance")
	}

	descendGeneratedTo(t, g, parentDepth)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[parentDepth], "BRANCH_LAIR")
	end := descendBranch(t, g, lair, 5)
	ids := end.VaultIDs()

	if end.BranchID != "BRANCH_LAIR" || end.LocalDepth != 5 ||
		end.VaultID() == "" || !slices.Contains(ids, end.VaultID()) {
		t.Fatalf("Lair ending = %s:%d primary %q history %v",
			end.BranchID, end.LocalDepth, end.VaultID(), ids)
	}

	paired := map[string]bool{
		"wormcave":                         true,
		"hangedman_lair_caniforms_friends": true,
		"guppyfry_lair_end_dragon":         true,
		"hangedman_lair_in_review":         true,
		"hangedman_lair_tendril_chambers":  true,
	}

	if paired[end.VaultID()] && len(ids) < 2 {
		t.Fatalf("small Lair ending %q has no saved partner", end.VaultID())
	}

	// The enlarged travel-only health is not a legal saved character.
	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore Lair:5: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Lair:5 ending changed across restore")
	}
}
