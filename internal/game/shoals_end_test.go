package game

import (
	"reflect"
	"slices"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/vault"
)

// Find a scheduled Shoals run so the entrance, branch stairs, and finale
// come from ordinary generated play rather than a fabricated test floor.
func shoalsRun(t *testing.T) *Game {
	t.Helper()

	for seed := uint64(400); seed < 420; seed++ {
		g, err := NewDungeonGame(seed,
			"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatal(err)
		}

		if g.branchSchedule.WaterBranchID == "BRANCH_SHOALS" {
			t.Cleanup(func() {
				_ = g.Close()
			})

			return g
		}

		_ = g.Close()
	}

	t.Fatal("seed window has no Shoals schedule")

	return nil
}

// An item mimic has the rune's displayed kind but cannot be the real
// historical rune record that validates a branch ending.
func realShoalsRune(record vault.Record) bool {
	if !runeRecord(record, "RUNE_SHOALS") {
		return false
	}

	for _, argument := range record.Arguments {
		if argument.Name == "mimic" && argument.Bool {
			return false
		}
	}

	return true
}

// Mutate only one Shoals floor in a copy of the save, then require the
// same restore path used by players to reject the forged history.
func rejectShoalsHistory(t *testing.T, g *Game, end *Level,
	change func(*save.LevelRecord)) {
	t.Helper()

	forged := g.Snapshot()
	found := false

	for index := range forged.Levels {
		if forged.Levels[index].ID == end.ID {
			change(&forged.Levels[index])
			found = true
			break
		}
	}

	if !found {
		t.Fatal("Shoals end is absent from its own snapshot")
	}

	bad, err := Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil {
		t.Fatal("forged Shoals history was accepted")
	}
}

// Travel through the scheduled entrance and all four branch floors. The
// authored finale must own one real rune and survive a Go save round trip.
func TestShoalsEndVaultAppearsOnTravel(t *testing.T) {
	g := shoalsRun(t)
	lairParent := 0
	shoalsParent := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_LAIR" {
			lairParent = entry.ParentDepth
		}

		if entry.BranchID == "BRANCH_SHOALS" {
			shoalsParent = entry.ParentDepth
		}
	}

	if lairParent == 0 || shoalsParent == 0 {
		t.Fatal("Shoals run has no Lair and Shoals schedule")
	}

	descendGeneratedTo(t, g, lairParent)

	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max

	lair := followBranch(t, g, g.levels[lairParent], "BRANCH_LAIR")
	lair = descendBranch(t, g, lair, shoalsParent)
	shoals := followBranch(t, g, lair, "BRANCH_SHOALS")
	parent := descendBranch(t, g, shoals, 3)
	end := descendBranch(t, g, parent, 4)

	if end.BranchID != "BRANCH_SHOALS" ||
		end.LocalDepth != 4 ||
		!slices.Contains(end.VaultIDs(), end.VaultID()) {
		t.Fatalf("Shoals end identity = %s:%d vault %s ids %v",
			end.BranchID, end.LocalDepth,
			end.VaultID(), end.VaultIDs())
	}

	historical := 0
	runeX, runeY := 0, 0
	runeOwner := ""

	for _, record := range end.VaultRecords() {
		if realShoalsRune(record) {
			if !slices.Contains(end.VaultIDs(), record.SourceID) {
				t.Fatalf("Shoals rune owner %s is absent from history",
					record.SourceID)
			}

			historical++
			runeX = record.X
			runeY = record.Y
			runeOwner = record.SourceID
		}
	}

	if historical != 1 {
		t.Fatalf("Shoals:4 has %d historical real runes", historical)
	}

	health.Max = 18
	health.Current = 18

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatalf("valid Shoals end save: %v", err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Shoals end changed across restore")
	}

	// Changing an existing source record to another known theme cannot
	// make that helper the owner of the chosen finale's real rune.
	forged := g.Snapshot()

	for index := range forged.Levels {
		floor := &forged.Levels[index]

		if floor.ID != end.ID {
			continue
		}

		for recordIndex, record := range floor.VaultRecords {
			if !realShoalsRune(record) {
				continue
			}

			owner := "shoals_garden_rune"

			if record.SourceID == owner {
				owner = "shoalhut_rune"
			}

			floor.VaultRecords[recordIndex].SourceID = owner
			break
		}
	}

	bad, err := Restore(forged)

	if bad != nil {
		_ = bad.Close()
	}

	if err == nil || !strings.Contains(err.Error(), "Shoals end") {
		t.Fatalf("forged Shoals rune owner was accepted: %v", err)
	}

	// A controller, its chosen rune child, and the sole real-rune record
	// must agree. Each mutation keeps all other saved floor facts intact.
	rejectShoalsHistory(t, g, end, func(floor *save.LevelRecord) {
		other := "shoals_end_simple"

		if floor.VaultID == other {
			other = "shoals_end_hellmonk_storm_palace"
		}

		floor.VaultID = other
	})

	rejectShoalsHistory(t, g, end, func(floor *save.LevelRecord) {
		other := "shoals_garden_rune"

		if runeOwner == other {
			other = "shoalhut_rune"
		}

		for index, id := range floor.VaultIDs {
			if id == runeOwner {
				floor.VaultIDs[index] = other
				return
			}
		}

		// Direct encompass endings own their rune in a nested map whose
		// history also has to be retained.
		t.Fatalf("Shoals rune child %s is absent from history", runeOwner)
	})

	rejectShoalsHistory(t, g, end, func(floor *save.LevelRecord) {
		for _, record := range floor.VaultRecords {
			if realShoalsRune(record) {
				floor.VaultRecords = append(floor.VaultRecords, record)
				return
			}
		}

		t.Fatal("Shoals real rune record is absent from history")
	})

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
		t.Fatal("Shoals:4 has no free return stair")
	}

	health.Max = 10000
	health.Current = health.Max

	if err := end.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	// A live siren can legitimately forbid stair use. Clear that combat
	// status so this assertion checks the reciprocal link itself.
	g.scripts.Components()["character.player_mesmerism"].Remove(g.player)

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != parent.ID ||
		up.View.PlayerX != ascent.ToX || up.View.PlayerY != ascent.ToY {
		t.Fatalf("Shoals end return = level %d cell (%d,%d), %v",
			up.View.LevelID, up.View.PlayerX, up.View.PlayerY, err)
	}

	g.scripts.Components()["character.player_mesmerism"].Remove(g.player)

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != end.ID ||
		down.View.PlayerX != ascent.X || down.View.PlayerY != ascent.Y {
		t.Fatalf("Shoals end reciprocal descent = level %d cell (%d,%d), messages %v, %v",
			down.View.LevelID, down.View.PlayerX, down.View.PlayerY,
			down.View.Messages, err)
	}

	collectRune(t, g, end, runeX, runeY, "RUNE_SHOALS")
}
