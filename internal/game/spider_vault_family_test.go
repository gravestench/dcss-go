package game

import (
	"testing"

	"crawl/internal/vault"
)

// The scheduled Spider stair comes from the keyed O cell of one source
// entry, rather than a synthetic doorway beside an unrelated map.
func TestScheduledSpiderEntryUsesSourceMap(t *testing.T) {
	g := spiderRun(t)

	lairParent := 0
	spiderParent := 0

	for _, entry := range g.branchSchedule.Entries {
		switch entry.BranchID {
		case "BRANCH_LAIR":
			lairParent = entry.ParentDepth

		case "BRANCH_SPIDER":
			spiderParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || spiderParent == 0 {
		t.Fatal("generated schedule has no Lair-to-Spider route")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	parent := descendBranch(t, g, lair, spiderParent)
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_SPIDER" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.SourceFeature != "DNGN_ENTER_SPIDER" {
		t.Fatalf("Spider entrance link = %+v", entrance)
	}

	entryID := ""

	for _, record := range parent.VaultRecords() {
		if record.Kind == vault.KindFeature &&
			record.Identity == "enter_spider_nest" &&
			record.X == entrance.X &&
			record.Y == entrance.Y {
			entryID = record.SourceID
		}
	}

	if entryID == "" {
		t.Fatal("scheduled Spider stair has no source KFEAT record")
	}

	inHistory := false

	for _, id := range parent.VaultIDs() {
		if id == entryID {
			inHistory = true
		}
	}

	if !inHistory {
		t.Fatalf("Spider entry map %s is absent from saved history", entryID)
	}

	health.Max = 18
	health.Current = 18

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatalf("authored Spider entry save: %v", err)
	}

	defer restored.Close()
	linked, found := restored.levels[parent.ID].StairAt(
		entrance.X, entrance.Y)

	if !found || linked != entrance {
		t.Fatalf("restored Spider entry link = %+v, found %t",
			linked, found)
	}

	health.Max = 10000
	health.Current = health.Max

	clearSpiderGateGuard(t, g, parent)

	child := followBranch(t, g, parent, "BRANCH_SPIDER")

	if child.BranchID != "BRANCH_SPIDER" || child.LocalDepth != 1 {
		t.Fatalf("Spider entry destination = %s:%d",
			child.BranchID, child.LocalDepth)
	}

	parentLink, found := parent.StairAt(entrance.X, entrance.Y)

	if !found ||
		parentLink.Pending ||
		parentLink.ToLevelID != child.ID {
		t.Fatalf("resolved Spider parent link = %+v, found %t",
			parentLink, found)
	}

	returnLink, found := child.StairAt(parentLink.ToX, parentLink.ToY)

	if !found ||
		returnLink.ToLevelID != parent.ID ||
		returnLink.ToX != entrance.X ||
		returnLink.ToY != entrance.Y {
		t.Fatalf("Spider reciprocal link = %+v, found %t",
			returnLink, found)
	}

	if err := child.MoveActor(g.player, returnLink.X, returnLink.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	if up.View.LevelID != parent.ID {
		t.Fatalf("Spider reciprocal ascent = %d, %v",
			up.View.LevelID, err)
	}
}

// Normal play would defeat a guard before taking its stair. These travel
// tests move the player directly, so they clear only an occupied gate cell.
func clearSpiderGateGuard(t *testing.T, g *Game, parent *Level) {
	t.Helper()

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID != "BRANCH_SPIDER" {
			continue
		}

		actor, occupied := parent.ActorAt(link.X, link.Y)

		if !occupied || actor == g.player {
			return
		}

		for _, item := range g.stores.CarriedBy.Entities() {
			carrier, _ := g.stores.CarriedBy.Get(item)

			if carrier.Holder == actor && !g.world.DestroyEntity(item) {
				t.Fatalf("remove Spider gate guard item %d", item)
			}
		}

		if err := parent.RemoveActor(actor); err != nil {
			t.Fatal(err)
		}

		if !g.world.DestroyEntity(actor) {
			t.Fatalf("remove Spider gate guard %d", actor)
		}

		return
	}
}
