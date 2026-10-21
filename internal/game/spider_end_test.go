package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"
)

// Find a normal run whose Lair poison sibling is Spider. The saved branch
// schedule then owns both its entrance and all subsequent floor links.
func spiderRun(t *testing.T) *Game {
	t.Helper()

	for seed := uint64(400); seed < 420; seed++ {
		g, err := NewDungeonGame(seed,
			"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if g.branchSchedule.PoisonBranchID == "BRANCH_SPIDER" {
			t.Cleanup(func() {
				_ = g.Close()
			})

			return g
		}

		_ = g.Close()
	}

	t.Fatal("seed window has no Spider schedule")

	return nil
}

// A source ending must provide the primary map, exactly one ECS rune item,
// and reciprocal Spider:3 stairs. Pickup must survive a Go save round trip.
func TestSpiderEndVaultAppearsOnTravel(t *testing.T) {
	g := spiderRun(t)
	lairParent := 0
	spiderParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SPIDER" {
			spiderParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || spiderParent == 0 {
		t.Fatal("Spider run has no Lair and Spider schedule")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	lair = descendBranch(t, g, lair, spiderParent)
	clearSpiderGateGuard(t, g, lair)
	spider := followBranch(t, g, lair, "BRANCH_SPIDER")
	parent := descendBranch(t, g, spider, 3)
	end := descendBranch(t, g, parent, 4)

	if end.BranchID != "BRANCH_SPIDER" ||
		end.LocalDepth != 4 ||
		!slices.Contains(end.VaultIDs(), end.VaultID()) {
		t.Fatalf("Spider end identity = %s:%d vault %s ids %v",
			end.BranchID, end.LocalDepth,
			end.VaultID(), end.VaultIDs())
	}

	historical := 0

	for _, record := range end.VaultRecords() {
		if runeRecord(record, "RUNE_SPIDER") {
			if record.SourceID != end.VaultID() {
				t.Fatalf("Spider rune source %s differs from end %s",
					record.SourceID, end.VaultID())
			}

			historical++
		}
	}

	if historical != 1 {
		t.Fatalf("Spider:4 has %d historical rune records", historical)
	}

	runeX, runeY := 0, 0
	liveRunes := 0

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if onFloor &&
			position.LevelID == end.ID &&
			item.KindID == "RUNE_SPIDER" {
			runeX = position.X
			runeY = position.Y
			liveRunes++
		}
	}

	if liveRunes != 1 {
		t.Fatalf("Spider:4 has %d live gossamer runes", liveRunes)
	}

	// Travel-only health is not a legal character profile in a save.
	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("valid Spider end save: %v", err)
	}

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Spider end changed across restore")
	}

	_ = restored.Close()

	forged := g.Snapshot()

	for index := range forged.Levels {
		floor := &forged.Levels[index]

		if floor.ID == end.ID {
			floor.VaultID = "snake_pit"
			break
		}
	}

	bad, err := Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil {
		t.Fatal("forged Spider end identity was accepted")
	}

	if !strings.Contains(err.Error(), "Spider end") {
		t.Fatalf("forged Spider end identity = %v", err)
	}

	// A known map outside this floor's history cannot hide a second rune.
	forged = g.Snapshot()
	other := "spider_rune_water"

	if end.VaultID() == other {
		other = "grunt_spider_rune_circles"
	}

	for index := range forged.Levels {
		floor := &forged.Levels[index]

		if floor.ID != end.ID {
			continue
		}

		for _, record := range floor.VaultRecords {
			if runeRecord(record, "RUNE_SPIDER") {
				record.SourceID = other
				floor.VaultRecords = append(floor.VaultRecords, record)
				break
			}
		}
	}

	bad, err = Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil {
		t.Fatal("forged Spider rune history was accepted")
	}

	if !strings.Contains(err.Error(), "Spider end") {
		t.Fatalf("forged Spider rune history = %v", err)
	}

	var ascent StairLink

	for _, link := range end.StairLinks() {
		if link.ToLevelID == parent.ID && link.Unavailable == "" {
			if _, occupied := end.ActorAt(link.X, link.Y); !occupied {
				ascent = link
				break
			}
		}
	}

	if ascent.ToLevelID != parent.ID {
		t.Fatal("Spider:4 has no free return stair")
	}

	health.Max = 10000
	health.Current = health.Max

	if err := end.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		up.View.LevelID != parent.ID ||
		up.View.PlayerX != ascent.ToX ||
		up.View.PlayerY != ascent.ToY {
		t.Fatalf("Spider end return = %+v, %v", up.View, err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil ||
		down.View.LevelID != end.ID ||
		down.View.PlayerX != ascent.X ||
		down.View.PlayerY != ascent.Y {
		t.Fatalf("Spider end reciprocal descent = %+v, %v", down.View, err)
	}

	collectRune(t, g, end, runeX, runeY, "RUNE_SPIDER")
}
