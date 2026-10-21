package game

import (
	"testing"

	"crawl/internal/vault"
)

// A scheduled Snake link must use the O cell from a source DES entry map.
// Its saved source identity and reciprocal stair survive a restore.
func TestScheduledSnakeEntryUsesSourceMap(t *testing.T) {
	g := snakeRun(t)
	lairParent := 0
	snakeParent := 0

	for _, entry := range g.branchSchedule.Entries {
		switch entry.BranchID {
		case "BRANCH_LAIR":
			lairParent = entry.ParentDepth
		case "BRANCH_SNAKE":
			snakeParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || snakeParent == 0 {
		t.Fatal("generated schedule has no Lair-to-Snake route")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	parent := descendBranch(t, g, lair, snakeParent)
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_SNAKE" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.SourceFeature != "DNGN_ENTER_SNAKE" {
		t.Fatalf("Snake entrance link = %+v", entrance)
	}

	entryID := ""

	for _, record := range parent.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_snake_pit" &&
			record.X == entrance.X && record.Y == entrance.Y {
			entryID = record.SourceID
		}
	}

	if entryID == "" {
		t.Fatal("scheduled Snake stair has no source KFEAT record")
	}

	inHistory := false

	for _, id := range parent.VaultIDs() {
		if id == entryID {
			inHistory = true
		}
	}

	if !inHistory {
		t.Fatalf("Snake entry map %s is absent from saved history", entryID)
	}

	health.Max = 18
	health.Current = 18

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("authored Snake entry save: %v", err)
	}

	defer restored.Close()
	linked, found := restored.levels[parent.ID].StairAt(
		entrance.X, entrance.Y)

	if !found || linked != entrance {
		t.Fatalf("restored Snake entry link = %+v, found %t",
			linked, found)
	}

	health.Max = 10000
	health.Current = health.Max

	child := followBranch(t, g, parent, "BRANCH_SNAKE")

	if child.BranchID != "BRANCH_SNAKE" || child.LocalDepth != 1 {
		t.Fatalf("Snake entry destination = %s:%d",
			child.BranchID, child.LocalDepth)
	}

	parentLink, found := parent.StairAt(entrance.X, entrance.Y)

	if !found || parentLink.Pending || parentLink.ToLevelID != child.ID {
		t.Fatalf("resolved Snake parent link = %+v, found %t",
			parentLink, found)
	}

	returnLink, found := child.StairAt(parentLink.ToX, parentLink.ToY)

	if !found || returnLink.ToLevelID != parent.ID ||
		returnLink.ToX != entrance.X || returnLink.ToY != entrance.Y {
		t.Fatalf("Snake reciprocal link = %+v, found %t",
			returnLink, found)
	}

	if err := child.MoveActor(g.player, returnLink.X, returnLink.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != parent.ID {
		t.Fatalf("Snake reciprocal ascent = %d, %v",
			up.View.LevelID, err)
	}
}
