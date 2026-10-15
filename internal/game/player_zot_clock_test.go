package game

import (
	"encoding/json"
	"strings"
	"testing"
)

func dungeonZotAut(t *testing.T, g *Game) int64 {
	t.Helper()

	store := g.scripts.Components()["world.zot_clock"]

	if store == nil {
		t.Fatal("Lua Zot clock component is missing")
	}

	clock, found := store.Get(g.player)

	if !found {
		t.Fatal("player has no Zot clock")
	}

	value, err := clock.Get("branch_aut")

	if err != nil {
		t.Fatal(err)
	}

	branchAut := value.(map[string]any)

	if len(branchAut) != 1 {
		t.Fatalf("new player has %d Zot branch clocks, want one", len(branchAut))
	}

	for _, current := range branchAut {
		return current.(int64)
	}

	return 0
}

func TestDungeonZotClockStartsSpendsAndSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	var otherBranch *Level

	for id, level := range g.levels {
		if id != 1 && id != 2 {
			otherBranch = level
		}
	}

	if otherBranch == nil ||
		g.levels[1].BranchID == "" ||
		g.levels[2].BranchID != g.levels[1].BranchID ||
		otherBranch.BranchID == g.levels[1].BranchID {
		t.Fatal("generated levels lack distinct Dungeon and Abyss owners")
	}

	if got := dungeonZotAut(t, g); got != 210000 {
		t.Fatalf("new Dungeon clock = %d, want 210000", got)
	}

	step, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	want := int64(210000 + step.Spent)

	if got := dungeonZotAut(t, g); got != want {
		t.Fatalf("clock after wait = %d, want %d", got, want)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if got := dungeonZotAut(t, restored); got != want {
		t.Fatalf("restored clock = %d, want %d", got, want)
	}

	if err := restored.levels[1].MoveActor(restored.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	descent, err := restored.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	want = want - 60000 + int64(descent.Spent)

	if got := dungeonZotAut(t, restored); got != want {
		t.Fatalf("clock after descent = %d, want %d", got, want)
	}

	ascent, err := restored.Step(Command{Kind: CommandUpstairs})

	if err != nil {
		t.Fatal(err)
	}

	want += int64(ascent.Spent)

	if got := dungeonZotAut(t, restored); got != want {
		t.Fatalf("clock after revisiting D:1 = %d, want %d", got, want)
	}
}

func TestRestoreRejectsInvalidZotClock(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	for entityIndex := range snapshot.Entities {
		if snapshot.Entities[entityIndex].ID != uint64(g.player) {
			continue
		}

		for componentIndex := range snapshot.Entities[entityIndex].Dynamic {
			record := &snapshot.Entities[entityIndex].Dynamic[componentIndex]

			if record.Schema != "world.zot_clock" {
				continue
			}

			var branches map[string]int64

			if err := json.Unmarshal(record.Values["branch_aut"], &branches); err != nil {
				t.Fatal(err)
			}

			for id := range branches {
				branches[id] = -1
			}

			corrupt, err := json.Marshal(branches)

			if err != nil {
				t.Fatal(err)
			}

			record.Values["branch_aut"] = corrupt
		}
	}

	_, err := Restore(snapshot)

	if err == nil ||
		!strings.Contains(err.Error(), "invalid Zot clock") {
		t.Fatalf("expected invalid clock rejection, got %v", err)
	}
}

func TestRestoreRejectsWrongLevelBranch(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	var otherBranch string

	for _, level := range snapshot.Levels {
		if level.ID != 1 && level.ID != 2 {
			otherBranch = level.BranchID
		}
	}

	if otherBranch == "" {
		t.Fatal("snapshot has no other branch")
	}

	for index := range snapshot.Levels {
		if snapshot.Levels[index].ID == 1 {
			snapshot.Levels[index].BranchID = otherBranch
		}
	}

	_, err := Restore(snapshot)

	if err == nil ||
		!strings.Contains(err.Error(), "wrong branch owner") {
		t.Fatalf("expected branch ownership rejection, got %v", err)
	}
}
