package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/game"
	"dcrawl-go/internal/terrain"
)

func doorModel(t *testing.T, cells map[[2]int]byte) *AppModel {
	t.Helper()

	m := pregameModel(t)
	started, err := game.NewScenario(1, "WPN_RAPIER", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	snapshot := started.Snapshot()
	started.Close()

	for cell, glyph := range cells {
		x, y := cell[0], cell[1]
		if glyph == '+' {
			snapshot.Levels[0].Cells[y][x] = terrain.ClosedDoor
		} else {
			snapshot.Levels[0].Cells[y][x] = terrain.OpenDoor
		}
	}

	m.game, err = game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	m.screen = ScreenPlay

	return m
}

func TestDoorKeysActAutomaticallyForOneNeighbor(t *testing.T) {
	m := doorModel(t, map[[2]int]byte{
		{2, 1}: '+',
	})

	start := m.game.View().CurrentAut

	m.handleKey("O")

	if m.game.View().CurrentAut != start+10 ||
		m.game.View().Cells[1*m.game.View().Width+2].Glyph != '\'' {
		t.Fatalf("O did not open the adjacent door: %s", plainApp(m))
	}

	m.handleKey("C")

	if m.game.View().CurrentAut != start+20 ||
		m.game.View().Cells[1*m.game.View().Width+2].Glyph != '+' {
		t.Fatalf("C did not close the adjacent door: %s", plainApp(m))
	}
}

func TestDoorDirectionPromptAndCancel(t *testing.T) {
	m := doorModel(t, map[[2]int]byte{
		{2, 1}: '+',
		{2, 2}: '+',
	})

	start := m.game.View().CurrentAut

	m.handleKey("O")

	if m.pendingDoor != game.CommandOpenDoor ||
		!strings.Contains(plainApp(m), "Open which direction") ||
		m.game.View().CurrentAut != start {
		t.Fatalf("O did not ask for direction: %s", plainApp(m))
	}

	m.handleKey("esc")

	if m.pendingDoor != 0 || m.game.View().CurrentAut != start {
		t.Fatal("door direction cancellation spent time")
	}

	m.handleKey("O")
	m.handleKey("l")

	if m.pendingDoor != 0 ||
		m.game.View().CurrentAut != start+10 ||
		m.game.View().Cells[2*m.game.View().Width+2].Glyph != '\'' {
		t.Fatalf("directional open did not change connected group: %s", plainApp(m))
	}

	m.handleKey("C")
	m.handleKey("l")

	if m.pendingDoor != 0 ||
		m.game.View().CurrentAut != start+20 ||
		m.game.View().Cells[2*m.game.View().Width+2].Glyph != '+' {
		t.Fatalf("directional close did not change connected group: %s", plainApp(m))
	}
}
