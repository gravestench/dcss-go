package game

import (
	"testing"

	"crawl/internal/vault"
)

// A scheduled Slime link on Lair must come from one authored DES entry,
// and its keyed O cell must be the live stair saved with that parent floor.
func TestScheduledSlimeEntryUsesSourceMap(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	lairParent := 0
	slimeParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SLIME" {
			slimeParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || slimeParent == 0 {
		t.Fatal("generated schedule has no Lair-to-Slime route")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	parent := descendBranch(t, g, lair, slimeParent)
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_SLIME" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.SourceFeature != "DNGN_ENTER_SLIME" {
		t.Fatalf("Slime entrance link = %+v", entrance)
	}

	entryID := ""

	for _, record := range parent.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_slime_pits" &&
			record.X == entrance.X && record.Y == entrance.Y {
			entryID = record.SourceID
		}
	}

	if entryID == "" {
		t.Fatal("scheduled Slime stair has no source KFEAT record")
	}

	inHistory := false

	for _, id := range parent.VaultIDs() {
		if id == entryID {
			inHistory = true
		}
	}

	if !inHistory {
		t.Fatalf("Slime entry map %s is absent from saved history", entryID)
	}

	health.Max = 18
	health.Current = 18

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("authored Slime entry save: %v", err)
	}

	defer restored.Close()
	linked, found := restored.levels[parent.ID].StairAt(
		entrance.X, entrance.Y)

	if !found || linked != entrance {
		t.Fatalf("restored Slime entry link = %+v, found %t",
			linked, found)
	}

	health.Max = 10000
	health.Current = health.Max

	child := followBranch(t, g, parent, "BRANCH_SLIME")

	if child.BranchID != "BRANCH_SLIME" || child.LocalDepth != 1 {
		t.Fatalf("Slime entry destination = %s:%d",
			child.BranchID, child.LocalDepth)
	}

	if child.VaultID() == "" {
		t.Fatal("Slime:1 did not place an authored branch vault")
	}
}
