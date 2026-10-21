package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// A run chooses entrances once, and save/restore retains the exact choice.
// The scheduled parent need not be generated yet when the player saves D:1.
func TestGeneratedBranchScheduleSurvivesRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 421)
	snapshot := g.Snapshot()

	if snapshot.BranchSchedule == nil || len(snapshot.BranchSchedule.Entries) == 0 {
		t.Fatal("generated run has no saved branch schedule")
	}

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot.BranchSchedule, restored.Snapshot().BranchSchedule) {
		t.Fatal("branch schedule changed across restore")
	}
}

// Save validation consults the effective Lua branch catalog before trusting
// an entrance depth, even if that parent's grid has not been generated yet.
func TestGeneratedBranchScheduleRejectsTamperedDepth(t *testing.T) {
	g := newGeneratedTestGame(t, 422)
	snapshot := g.Snapshot()
	changed := false

	for index := range snapshot.BranchSchedule.Entries {
		entry := &snapshot.BranchSchedule.Entries[index]

		if entry.BranchID == "BRANCH_LAIR" {
			entry.ParentDepth = 1
			changed = true
			break
		}
	}

	if !changed {
		t.Fatal("Lair has no scheduled entrance")
	}

	if restored, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "BRANCH_LAIR") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("tampered Lair schedule error = %v", err)
	}
}

// A generated save cannot infer its future entrance graph from its seed:
// turn actions may already have consumed unrelated random streams.
func TestGeneratedBranchScheduleRejectsMissingOrInvalidPair(t *testing.T) {
	g := newGeneratedTestGame(t, 424)
	missing := g.Snapshot()
	missing.BranchSchedule = nil

	if restored, err := Restore(missing); err == nil ||
		!strings.Contains(err.Error(), "branch schedule") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("missing schedule error = %v", err)
	}

	invalid := g.Snapshot()
	invalid.BranchSchedule.WaterBranchID = "BRANCH_ZIGGURAT"

	if restored, err := Restore(invalid); err == nil ||
		!strings.Contains(err.Error(), "Lair branch pair") {
		if restored != nil {
			_ = restored.Close()
		}

		t.Fatalf("invalid water pair error = %v", err)
	}
}

// The chosen Dungeon floor shows a labelled source entrance. Its pending
// destination and cell stay fixed across a save before branch entry.
func TestScheduledLairEntrancePersistsOnParentFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	depth := 0

	for _, entry := range g.Snapshot().BranchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			depth = entry.ParentDepth
		}
	}

	if depth == 0 {
		t.Fatal("Lair has no scheduled parent depth")
	}

	descendGeneratedTo(t, g, depth)
	var entrance StairLink

	for _, link := range g.levels[depth].StairLinks() {
		if link.TargetBranchID == "BRANCH_LAIR" {
			entrance = link
			break
		}
	}

	if entrance.SourceFeature != "DNGN_ENTER_LAIR" ||
		!entrance.Pending || entrance.Unavailable != "" ||
		entrance.ToLevelID <= 0 {
		t.Fatalf("Lair entrance = %+v", entrance)
	}

	if g.levels[depth].Cells()[entrance.Y][entrance.X] != terrain.StairsDown {
		t.Fatal("Lair entrance does not occupy a linked stair cell")
	}

	entryID := ""

	for _, record := range g.levels[depth].VaultRecords() {
		if record.X == entrance.X && record.Y == entrance.Y &&
			record.Kind == vault.KindFeature &&
			record.Identity == "enter_lair" {
			entryID = record.SourceID
		}
	}

	if entryID == "" || !slices.Contains(g.levels[depth].VaultIDs(), entryID) {
		t.Fatalf("Lair entrance has no saved authored source: %q", entryID)
	}

	for _, record := range g.levels[depth].VaultRecords() {
		if record.X == entrance.X && record.Y == entrance.Y &&
			record.SourceID != entryID {
			t.Fatal("extra vault overlapped protected Lair entrance")
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	linked, found := restored.levels[depth].StairAt(entrance.X, entrance.Y)

	if !found || linked != entrance {
		t.Fatalf("restored Lair entrance = %+v, found %t", linked, found)
	}

	forged := g.Snapshot()

	for levelIndex := range forged.Levels {
		level := &forged.Levels[levelIndex]

		if level.ID != depth {
			continue
		}

		for stairIndex := range level.Stairs {
			stair := &level.Stairs[stairIndex]

			if stair.TargetBranchID == "BRANCH_LAIR" {
				stair.SourceFeature = "DNGN_ENTER_ORC"
			}
		}
	}

	if bad, err := Restore(forged); err == nil ||
		!strings.Contains(err.Error(), "invalid branch entrance") {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatalf("forged source feature error = %v", err)
	}
}

// Enter through the saved source-labelled link. The child is generated only
// now and its return link must land on this exact parent cell after restore.
func TestScheduledLairEntryAndReturnSurviveRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	descendGeneratedTo(t, g, parentDepth)
	var entrance StairLink

	for _, link := range g.levels[parentDepth].StairLinks() {
		if link.TargetBranchID == "BRANCH_LAIR" {
			entrance = link
			break
		}
	}

	if !entrance.Pending {
		t.Fatal("Lair entrance is not a pending floor")
	}

	if err := g.levels[parentDepth].MoveActor(g.player,
		entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	child := g.levels[entrance.ToLevelID]

	if result.View.LevelID != entrance.ToLevelID || child == nil ||
		child.BranchID != "BRANCH_LAIR" || child.LocalDepth != 1 {
		t.Fatalf("Lair entry = %+v, level = %+v", result.View, child)
	}

	parentLink, found := g.levels[parentDepth].StairAt(entrance.X, entrance.Y)

	if !found || parentLink.Pending {
		t.Fatal("Lair parent entrance did not resolve")
	}

	returnLink, found := child.StairAt(parentLink.ToX, parentLink.ToY)

	if !found || returnLink.ToLevelID != parentDepth ||
		returnLink.ToX != entrance.X || returnLink.ToY != entrance.Y {
		t.Fatalf("Lair return link = %+v", returnLink)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.levels[entrance.ToLevelID].LocalDepth != 1 {
		t.Fatal("restored Lair lost its local depth")
	}

	wrongDepth := g.Snapshot()

	for index := range wrongDepth.Levels {
		if wrongDepth.Levels[index].ID == entrance.ToLevelID {
			wrongDepth.Levels[index].LocalDepth = 2
		}
	}

	if bad, err := Restore(wrongDepth); err == nil {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatal("forged Lair local depth restored")
	}

	brokenReturn := g.Snapshot()

	for levelIndex := range brokenReturn.Levels {
		level := &brokenReturn.Levels[levelIndex]

		if level.ID != entrance.ToLevelID {
			continue
		}

		for linkIndex := range level.Stairs {
			link := &level.Stairs[linkIndex]

			if link.ToLevelID == parentDepth {
				link.ToX++
				break
			}
		}
	}

	if bad, err := Restore(brokenReturn); err == nil {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatal("broken Lair return link restored")
	}
}

// Each source branch uses its own local depth and stable level IDs. Building
// the second floor must leave the other branch's scheduled frontier intact.
func TestGeneratedLairAndOrcSecondFloors(t *testing.T) {
	for _, branchID := range []string{"BRANCH_LAIR", "BRANCH_ORC"} {
		t.Run(branchID, func(t *testing.T) {
			g := newGeneratedTestGame(t, 423)
			// This test exercises branch generation and save links while
			// repeatedly taking stairs. A generated attacker can otherwise
			// kill the level-one player before the scheduled entrance.
			health, _ := g.stores.Health.Get(g.player)
			originalMax := health.Max
			health.Max = 100000
			health.Current = health.Max
			parentDepth := 0

			for _, entry := range g.branchSchedule.Entries {
				if entry.BranchID == branchID {
					parentDepth = entry.ParentDepth
					break
				}
			}

			descendGeneratedTo(t, g, parentDepth)
			var entrance StairLink

			for _, link := range g.levels[parentDepth].StairLinks() {
				if link.TargetBranchID == branchID {
					entrance = link
					break
				}
			}

			if !entrance.Pending {
				t.Fatal("branch entrance is not pending")
			}

			if err := g.levels[parentDepth].MoveActor(g.player,
				entrance.X, entrance.Y); err != nil {
				t.Fatal(err)
			}

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			first := g.levels[entrance.ToLevelID]
			var next StairLink

			for _, link := range first.StairLinks() {
				if !link.Pending || link.TargetBranchID != "" {
					continue
				}

				if _, occupied := first.ActorAt(link.X, link.Y); occupied {
					continue
				}

				next = link
				break
			}

			if !next.Pending {
				t.Fatal("first branch floor has no free down stair")
			}

			if err := first.MoveActor(g.player, next.X, next.Y); err != nil {
				t.Fatal(err)
			}

			result, err := g.Step(Command{Kind: CommandDownstairs})

			if err != nil {
				t.Fatal(err)
			}

			second := g.levels[next.ToLevelID]

			if second == nil || result.View.LevelID != next.ToLevelID ||
				second.BranchID != branchID || second.LocalDepth != 2 {
				t.Fatalf("second %s floor = %+v, view %+v",
					branchID, second, result.View)
			}

			health.Max = originalMax
			health.Current = originalMax

			restored, err := Restore(g.Snapshot())

			if err != nil {
				t.Fatal(err)
			}

			defer restored.Close()
		})
	}
}

// Source entrance selection covers more than Lair and Orc. Exercise every
// direct Dungeon child in a fresh run so a missing branch layout or roster
// cannot hide behind the two common branch integration examples.
func TestScheduledDungeonBranchesOpenOnFirstEntry(t *testing.T) {
	probe := newGeneratedTestGame(t, 423)
	entries := append([]save.BranchEntryRecord(nil),
		probe.branchSchedule.Entries...)

	for _, entry := range entries {
		if entry.ParentID != "BRANCH_DUNGEON" {
			continue
		}

		t.Run(entry.BranchID, func(t *testing.T) {
			g := newGeneratedTestGame(t, 423)
			descendGeneratedTo(t, g, entry.ParentDepth)
			var entrance StairLink

			for _, link := range g.levels[entry.ParentDepth].StairLinks() {
				if link.TargetBranchID == entry.BranchID {
					entrance = link
					break
				}
			}

			if !entrance.Pending {
				if !strings.Contains(entrance.Unavailable,
					"no ported primary layout") {
					t.Fatalf("scheduled entrance has no reason: %+v", entrance)
				}

				return
			}

			moveGeneratedPlayerToStair(t, g,
				g.levels[entry.ParentDepth], entrance)

			result, err := g.Step(Command{Kind: CommandDownstairs})

			if err != nil {
				t.Fatal(err)
			}

			child := g.levels[entrance.ToLevelID]

			if child == nil || result.View.LevelID != entrance.ToLevelID ||
				child.BranchID != entry.BranchID || child.LocalDepth != 1 {
				t.Fatalf("branch %s entry = %+v, level = %+v",
					entry.BranchID, result.View, child)
			}
		})
	}
}

// Lair's water choice is scheduled inside another generated branch. The
// source parent depth must use Lair-local coordinates, not its numeric ID.
func TestScheduledLairWaterChildOpens(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	waterID := g.branchSchedule.WaterBranchID
	lairParent := 0
	waterParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == waterID {
			waterParent = entry.ParentDepth
		}
	}

	descendGeneratedTo(t, g, lairParent)
	var lairEntrance StairLink

	for _, link := range g.levels[lairParent].StairLinks() {
		if link.TargetBranchID == "BRANCH_LAIR" {
			lairEntrance = link
			break
		}
	}

	if err := g.levels[lairParent].MoveActor(g.player,
		lairEntrance.X, lairEntrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	level := g.levels[lairEntrance.ToLevelID]

	for depth := 1; depth < waterParent; depth++ {
		var next StairLink

		for _, link := range level.StairLinks() {
			if link.Pending && link.TargetBranchID == "" {
				if _, occupied := level.ActorAt(link.X, link.Y); !occupied {
					next = link
					break
				}
			}
		}

		if !next.Pending {
			t.Fatalf("Lair:%d has no free down stair", depth)
		}

		if err := level.MoveActor(g.player, next.X, next.Y); err != nil {
			t.Fatal(err)
		}

		if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
			t.Fatal(err)
		}

		level = g.levels[next.ToLevelID]

		if level.BranchID != "BRANCH_LAIR" || level.LocalDepth != depth+1 {
			t.Fatalf("Lair continuation = %+v", level)
		}
	}

	var entrance StairLink

	for _, link := range level.StairLinks() {
		if link.TargetBranchID == waterID {
			entrance = link
			break
		}
	}

	if entrance.Unavailable != "" {
		t.Fatalf("selected water branch %s is unavailable: %s",
			waterID, entrance.Unavailable)
	}

	if !entrance.Pending {
		t.Fatal("water branch has no pending entrance")
	}

	if err := level.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	child := g.levels[entrance.ToLevelID]

	if child == nil || child.BranchID != waterID || child.LocalDepth != 1 {
		t.Fatalf("water branch entry = %+v", child)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
}

// Generating one branch must not consume or overwrite another scheduled
// entrance on a different Dungeon floor. Both frontiers survive save/load.
func TestIndependentLairAndOrcFrontiers(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := map[string]int{}

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" || entry.BranchID == "BRANCH_ORC" {
			parentDepth[entry.BranchID] = entry.ParentDepth
		}
	}

	firstBranch := "BRANCH_LAIR"
	otherBranch := "BRANCH_ORC"

	if parentDepth[otherBranch] > parentDepth[firstBranch] {
		firstBranch, otherBranch = otherBranch, firstBranch
	}

	descendGeneratedTo(t, g, parentDepth[firstBranch])
	var entered StairLink
	var other StairLink

	for _, link := range g.levels[parentDepth[firstBranch]].StairLinks() {
		if link.TargetBranchID == firstBranch {
			entered = link
		}
	}

	for _, link := range g.levels[parentDepth[otherBranch]].StairLinks() {
		if link.TargetBranchID == otherBranch {
			other = link
		}
	}

	if !entered.Pending || !other.Pending {
		t.Fatalf("missing independent frontiers: %+v, %+v", entered, other)
	}

	if err := g.levels[parentDepth[firstBranch]].MoveActor(g.player,
		entered.X, entered.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	remaining, found := g.levels[parentDepth[otherBranch]].StairAt(
		other.X, other.Y)

	if !found || remaining != other {
		t.Fatalf("other branch frontier changed: %+v", remaining)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	remaining, found = restored.levels[parentDepth[otherBranch]].StairAt(
		other.X, other.Y)

	if !found || remaining != other {
		t.Fatalf("restored other frontier changed: %+v", remaining)
	}
}
