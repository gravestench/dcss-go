package game

import (
	"reflect"
	"strings"
	"testing"
)

// A source-labelled Dungeon entrance opens the generated primary Vaults
// floors in sequence. The fifth floor remains a visible end-vault frontier
// until its distinct source category is ported.
func TestGeneratedVaultsPrimaryFloorsAndEndFrontier(t *testing.T) {
	g := newGeneratedTestGame(t, 423)
	parentDepth := 0

	for _, entry := range g.branchSchedule.Entries {
		if entry.BranchID == "BRANCH_VAULTS" {
			parentDepth = entry.ParentDepth
			break
		}
	}

	if parentDepth == 0 {
		t.Fatal("Vaults has no scheduled Dungeon entrance")
	}

	descendGeneratedTo(t, g, parentDepth)
	health, _ := g.stores.Health.Get(g.player)
	health.Max = 10000
	health.Current = health.Max
	parent := g.levels[parentDepth]
	var entrance StairLink

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_VAULTS" {
			entrance = link
			break
		}
	}

	if !entrance.Pending || entrance.Unavailable != "" {
		t.Fatalf("Vaults entrance = %+v", entrance)
	}

	if err := parent.MoveActor(g.player, entrance.X, entrance.Y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	level := g.levels[entrance.ToLevelID]
	roomHistory := make(map[int][]string)

	for depth := 1; depth <= 4; depth++ {
		if level == nil || level.BranchID != "BRANCH_VAULTS" ||
			level.LocalDepth != depth {
			t.Fatalf("Vaults:%d = %+v", depth, level)
		}

		ids := level.VaultIDs()

		if len(ids) == 0 {
			t.Fatalf("Vaults:%d lost its authored room history", depth)
		}

		roomHistory[level.ID] = ids

		var departure StairLink

		for _, link := range level.StairLinks() {
			if link.TargetBranchID != "" {
				continue
			}

			if actor, occupied := level.ActorAt(link.X, link.Y); occupied &&
				actor != g.player {
				continue
			}

			if link.Pending || strings.Contains(link.Unavailable, "Vaults:5") {
				departure = link
				break
			}
		}

		if depth == 4 {
			if departure.Pending || departure.ToLevelID != 0 ||
				!strings.Contains(departure.Unavailable, "Vaults:5") {
				t.Fatalf("Vaults:4 end stair = %+v", departure)
			}

			break
		}

		if !departure.Pending {
			t.Fatalf("Vaults:%d has no pending down stair", depth)
		}

		if err := level.MoveActor(g.player, departure.X, departure.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatal(err)
		}

		if result.View.LevelID != departure.ToLevelID {
			t.Fatalf("Vaults:%d descent through %+v stayed on %d with %d HP",
				depth, departure, result.View.LevelID, result.View.PlayerHP)
		}

		level = g.levels[departure.ToLevelID]
	}

	if g.levels[1105] != nil {
		t.Fatal("generic primary layout generated Vaults:5")
	}

	// Exercise a resolved stair in both directions. The save validator also
	// checks links, but live travel proves the exact landing is usable.
	var ascent StairLink

	for _, link := range level.StairLinks() {
		if link.ToLevelID != 1103 || link.Unavailable != "" {
			continue
		}

		if actor, occupied := level.ActorAt(link.X, link.Y); occupied &&
			actor != g.player {
			continue
		}

		ascent = link
		break
	}

	if ascent.ToLevelID != 1103 {
		t.Fatal("Vaults:4 has no free reciprocal stair to Vaults:3")
	}

	if err := level.MoveActor(g.player, ascent.X, ascent.Y); err != nil {
		t.Fatal(err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil || up.View.LevelID != 1103 ||
		up.View.PlayerX != ascent.ToX || up.View.PlayerY != ascent.ToY {
		t.Fatalf("Vaults return through %+v: view %+v, error %v",
			ascent, up.View, err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil || down.View.LevelID != level.ID ||
		down.View.PlayerX != ascent.X || down.View.PlayerY != ascent.Y {
		t.Fatalf("Vaults reciprocal descent through %+v: view %+v, error %v",
			ascent, down.View, err)
	}

	// The travel fixture has extra HP only to survive deep monsters while
	// crossing floors. Restore the source Human/Fighter maximum before save.
	health.Max = 18
	health.Current = 18

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.levels[level.ID] == nil {
		t.Fatal("Vaults:4 disappeared on restore")
	}

	for id, before := range roomHistory {
		after := restored.levels[id]

		if after == nil || !reflect.DeepEqual(after.VaultIDs(), before) {
			t.Fatalf("Vaults level %d room history changed on restore", id)
		}
	}

	forged := g.Snapshot()

	for levelIndex := range forged.Levels {
		floor := &forged.Levels[levelIndex]

		if floor.ID != level.ID {
			continue
		}

		for linkIndex := range floor.Stairs {
			link := &floor.Stairs[linkIndex]

			if !strings.Contains(link.Unavailable, "Vaults:5") {
				continue
			}

			link.ToLevelID = 1105
			link.Pending = true
			link.Unavailable = ""
			break
		}
	}

	if bad, err := Restore(forged); err == nil {
		if bad != nil {
			_ = bad.Close()
		}

		t.Fatal("forged Vaults:5 link restored")
	}
}
