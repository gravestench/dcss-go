package game

import (
	"reflect"
	"slices"
	"testing"

	"crawl/internal/vault"
)

// The one scheduled D:15 stair uses a source Depths map's keyed O cell.
// Travel, the exact return landing, and the chosen map survive a Go save.
func TestScheduledDepthsEntryUsesSourceMap(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 15)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	parent := g.levels[15]
	var entrance StairLink
	var foundEntrance bool

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_DEPTHS" {
			entrance = link
			foundEntrance = true
			break
		}
	}

	if !foundEntrance ||
		!entrance.Pending ||
		entrance.SourceFeature != "DNGN_ENTER_DEPTHS" {
		t.Fatalf("Depths entrance link = %+v, found %t",
			entrance, foundEntrance)
	}

	entryID := ""

	for _, record := range parent.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_depths" &&
			record.X == entrance.X && record.Y == entrance.Y {
			entryID = record.SourceID
		}
	}

	if entryID == "" || !slices.Contains(parent.VaultIDs(), entryID) {
		t.Fatalf("Depths source gate %q is absent from history %v",
			entryID, parent.VaultIDs())
	}

	child := followBranch(t, g, parent, "BRANCH_DEPTHS")

	if child.BranchID != "BRANCH_DEPTHS" || child.LocalDepth != 1 {
		t.Fatalf("Depths destination = %s:%d",
			child.BranchID, child.LocalDepth)
	}

	parentLink, found := parent.StairAt(entrance.X, entrance.Y)

	if !found ||
		parentLink.Pending ||
		parentLink.ToLevelID != child.ID {
		t.Fatalf("resolved Depths parent link = %+v, found %t",
			parentLink, found)
	}

	returnLink, found := child.StairAt(parentLink.ToX, parentLink.ToY)

	if !found ||
		returnLink.ToLevelID != parent.ID ||
		returnLink.ToX != entrance.X ||
		returnLink.ToY != entrance.Y {
		t.Fatalf("Depths reciprocal link = %+v, found %t",
			returnLink, found)
	}

	if err := child.MoveActor(g.player, returnLink.X,
		returnLink.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		up.View.LevelID != parent.ID {
		t.Fatalf("Depths return to Dungeon = %d, %v",
			up.View.LevelID, err)
	}

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("restore Depths gate: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Depths gate changed across restore")
	}
}
