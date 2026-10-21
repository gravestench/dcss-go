package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"crawl/internal/vault"
)

// Find a deterministic generated run whose Lair poison sibling is Snake.
// The chosen seed remains fixed by the saved schedule once the game begins.
func snakeRun(t *testing.T) *Game {
	t.Helper()

	for seed := uint64(400); seed < 408; seed++ {
		g, err := NewDungeonGame(seed,
			"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if g.branchSchedule.PoisonBranchID == "BRANCH_SNAKE" {
			t.Cleanup(func() {
				_ = g.Close()
			})

			return g
		}

		_ = g.Close()
	}

	t.Fatal("seed window has no Snake schedule")

	return nil
}

// Use the generated stair link, so the end floor receives the same parent
// state and exact reciprocal landing as normal play.
func followBranch(t *testing.T, g *Game, parent *Level,
	branchID string) *Level {
	t.Helper()

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID != branchID {
			continue
		}

		if !link.Pending || link.Unavailable != "" {
			t.Fatalf("%s entrance is sealed: %+v", branchID, link)
		}

		if err := parent.MoveActor(g.player, link.X, link.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatal(err)
		}

		child := g.levels[link.ToLevelID]

		if child == nil || result.View.LevelID != child.ID {
			t.Fatalf("%s descent = %+v", branchID, result.View)
		}

		return child
	}

	t.Fatalf("%s has no scheduled entrance", branchID)

	return nil
}

// Advance through a branch without substituting a fabricated level record.
func descendBranch(t *testing.T, g *Game, level *Level,
	lastDepth int) *Level {
	t.Helper()

	for level.LocalDepth < lastDepth {
		var departure StairLink

		for _, link := range level.StairLinks() {
			if link.Pending && link.TargetBranchID == "" {
				if _, occupied := level.ActorAt(link.X, link.Y); !occupied {
					departure = link
					break
				}
			}
		}

		if !departure.Pending {
			t.Fatalf("%s:%d has no free down stair",
				level.BranchID, level.LocalDepth)
		}

		if err := level.MoveActor(g.player,
			departure.X, departure.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatal(err)
		}

		level = g.levels[departure.ToLevelID]

		if level == nil || result.View.LevelID != level.ID {
			t.Fatalf("branch descent through %+v = %+v",
				departure, result.View)
		}
	}

	return level
}

// Saved typed history outlives the floor item after pickup. Find the
// authored real rune without relying on its current ECS entity position.
func runeRecord(record vault.Record, runeID string) bool {
	if record.Kind != vault.KindItem {
		return false
	}

	for _, argument := range record.Arguments {
		if argument.Name == "kind_id" &&
			argument.String == runeID {
			return true
		}
	}

	return false
}

// Neither an extra source rune nor a deleted one may be accepted as a
// valid branch ending, even though the live floor item can later disappear.
func rejectChangedSnakeRuneHistory(t *testing.T, g *Game,
	end *Level, duplicate bool, otherSource string) {
	t.Helper()

	forged := g.Snapshot()
	changed := false

	for levelIndex := range forged.Levels {
		floor := &forged.Levels[levelIndex]

		if floor.ID != end.ID {
			continue
		}

		for recordIndex, record := range floor.VaultRecords {
			if !runeRecord(record, "RUNE_SNAKE") {
				continue
			}

			if duplicate {
				if otherSource != "" {
					record.SourceID = otherSource
				}

				floor.VaultRecords = append(floor.VaultRecords, record)
			} else {
				floor.VaultRecords = append(floor.VaultRecords[:recordIndex],
					floor.VaultRecords[recordIndex+1:]...)
			}

			changed = true
			break
		}
	}

	if !changed {
		t.Fatal("Snake end has no rune history to corrupt")
	}

	bad, err := Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "Snake end") {
		t.Fatalf("forged Snake rune history = %v", err)
	}
}

// Exercise live pickup, then round-trip both player rune progress and the
// authored source record through the ordinary Go save.
func collectRune(t *testing.T, g *Game, end *Level, x, y int, runeID string) {
	t.Helper()

	if actor, occupied := end.ActorAt(x, y); occupied {
		for _, item := range g.stores.CarriedBy.Entities() {
			carrier, _ := g.stores.CarriedBy.Get(item)

			if carrier.Holder == actor && !g.world.DestroyEntity(item) {
				t.Fatalf("remove rune guard item %d", item)
			}
		}

		if err := end.RemoveActor(actor); err != nil ||
			!g.world.DestroyEntity(actor) {
			t.Fatalf("remove rune guard: %v", err)
		}
	}

	if err := end.MoveActor(g.player, x, y); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	// Some endings put an ambrosia potion on top of their rune. Pick up
	// each item on this one source cell until the rune enters saved progress.
	collectedRune := false

	for attempt := 0; attempt < 8; attempt++ {
		if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
			t.Fatal(err)
		}

		progress, found := g.scripts.Components()["character.runes"].Get(g.player)

		if !found {
			t.Fatal("player lost rune progress")
		}

		collected, err := progress.Get("collected")

		if err != nil {
			t.Fatal(err)
		}

		values, okay := collected.(map[string]any)

		if okay && values[runeID] == true {
			collectedRune = true
			break
		}
	}

	if !collectedRune {
		t.Fatalf("%s was not collected from its source cell", runeID)
	}

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("Snake rune pickup changed across restore")
	}
}

// Snake:4 must be one of its source end maps, with one live rune and a
// saved primary identity. Ordinary Snake layouts alone are insufficient.
func TestSnakeEndVaultAppearsOnTravel(t *testing.T) {
	g := snakeRun(t)
	lairParent := 0
	snakeParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SNAKE" {
			snakeParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || snakeParent == 0 {
		t.Fatal("Snake run has no Lair and Snake schedule")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent],
		"BRANCH_LAIR")
	lair = descendBranch(t, g, lair, snakeParent)
	snake := followBranch(t, g, lair, "BRANCH_SNAKE")
	end := descendBranch(t, g, snake, 4)

	if end.BranchID != "BRANCH_SNAKE" ||
		end.LocalDepth != 4 ||
		!slices.Contains(end.VaultIDs(), end.VaultID()) {
		t.Fatalf("Snake end identity = %s:%d vault %s ids %v",
			end.BranchID, end.LocalDepth,
			end.VaultID(), end.VaultIDs())
	}

	// Restore checks the primary ID against the effective end-vault family.
	// Assert the rune's source record points at that same selected map.
	sourceRunes := 0

	for _, record := range end.VaultRecords() {
		if runeRecord(record, "RUNE_SNAKE") {
			if record.SourceID != end.VaultID() {
				t.Fatalf("Snake rune source %s differs from end %s",
					record.SourceID, end.VaultID())
			}

			sourceRunes++
		}
	}

	if sourceRunes != 1 {
		t.Fatalf("Snake:4 has %d historical rune records", sourceRunes)
	}

	runeX, runeY := 0, 0
	runes := 0

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, onFloor := g.stores.Positions.Get(entity)

		if onFloor &&
			position.LevelID == end.ID &&
			item.KindID == "RUNE_SNAKE" {
			runeX = position.X
			runeY = position.Y
			runes++
		}
	}

	if runes != 1 {
		t.Fatalf("Snake:4 has %d serpentine runes", runes)
	}

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("valid Snake end save: %v", err)
	}

	_ = restored.Close()

	forged := g.Snapshot()

	for levelIndex := range forged.Levels {
		floor := &forged.Levels[levelIndex]

		if floor.ID == end.ID {
			floor.VaultID = "nicolae_shop_gadgets"
			break
		}
	}

	bad, err := Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "Snake end") {
		t.Fatalf("forged Snake end save = %v", err)
	}

	t.Run("missing rune record", func(t *testing.T) {
		rejectChangedSnakeRuneHistory(t, g, end, false, "")
	})

	t.Run("duplicate rune record", func(t *testing.T) {
		rejectChangedSnakeRuneHistory(t, g, end, true, "")
	})

	t.Run("rune record from unselected map", func(t *testing.T) {
		other := "snake_pit"

		if end.VaultID() == other {
			other = "snake_hunt"
		}

		if slices.Contains(end.VaultIDs(), other) {
			t.Fatalf("unexpected second Snake end %s", other)
		}

		rejectChangedSnakeRuneHistory(t, g, end, true, other)
	})

	t.Run("rune owned by another historical map", func(t *testing.T) {
		other := "snake_pit"

		if end.VaultID() == other {
			other = "snake_hunt"
		}

		forged := g.Snapshot()

		for index := range forged.Levels {
			floor := &forged.Levels[index]

			if floor.ID != end.ID {
				continue
			}

			floor.VaultIDs = append(floor.VaultIDs, other)

			for recordIndex, record := range floor.VaultRecords {
				if runeRecord(record, "RUNE_SNAKE") {
					floor.VaultRecords[recordIndex].SourceID = other
					break
				}
			}
		}

		bad, err := Restore(forged)

		if bad != nil {
			_ = bad.Close()
		}

		if err == nil {
			t.Fatal("rune from wrong historical end was accepted")
		}

		if !strings.Contains(err.Error(), "Snake end") {
			t.Fatalf("rune from wrong historical end = %v", err)
		}
	})

	// The generated end map still uses the branch's exact paired stairs.
	var ascent StairLink

	for _, link := range end.StairLinks() {
		if link.ToLevelID == 803 && link.Unavailable == "" {
			if _, occupied := end.ActorAt(link.X, link.Y); !occupied {
				ascent = link
				break
			}
		}
	}

	if ascent.ToLevelID != 803 {
		t.Fatal("Snake:4 has no free return stair")
	}

	health.Max = 10000
	health.Current = health.Max

	if err := end.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		up.View.LevelID != 803 ||
		up.View.PlayerX != ascent.ToX ||
		up.View.PlayerY != ascent.ToY {
		t.Fatalf("Snake end return = %+v, %v", up.View, err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil ||
		down.View.LevelID != end.ID ||
		down.View.PlayerX != ascent.X ||
		down.View.PlayerY != ascent.Y {
		t.Fatalf("Snake end reciprocal descent = %+v, %v", down.View, err)
	}

	collectRune(t, g, end, runeX, runeY, "RUNE_SNAKE")
}
