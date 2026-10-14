package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/save"
)

func TestNewRunSightAndOcclusion(t *testing.T) {
	g := newStepGame(t)
	view := g.View()
	if view.Width != 17 || view.Height != 9 || len(view.Cells) != 153 {
		t.Fatalf("view geometry: %+v", view)
	}
	if wall := view.Cells[2*17+2]; wall.Glyph != '#' || wall.State != Visible {
		t.Fatalf("blocking wall = %+v", wall)
	}
	if behind := view.Cells[3*17+3]; behind.Glyph != 0 || behind.State != Unknown {
		t.Fatalf("unknown cell leaked terrain: %+v", behind)
	}
	if len(view.Entities) == 0 {
		t.Fatal("player absent")
	}
}

func TestMovementRemembersTerrainButHidesEntities(t *testing.T) {
	g := newStepGame(t)
	item := potionID(t, g)
	position, _ := g.stores.Positions.Get(item)
	position.X, position.Y = 3, 3
	contains := func(v View, id uint64) bool {
		for _, entity := range v.Entities {
			if entity.ID == id {
				return true
			}
		}
		return false
	}
	if contains(g.View(), uint64(item)) {
		t.Fatal("unseen item leaked into view")
	}
	right, err := g.Step(Command{Kind: CommandMove, DX: 1})
	if err != nil {
		t.Fatal(err)
	}
	if right.View.Cells[3*17+3].State != Visible || !contains(right.View, uint64(item)) {
		t.Fatalf("newly visible item/terrain missing: %+v", right.View.Cells[3*17+3])
	}
	left, err := g.Step(Command{Kind: CommandMove, DX: -1})
	if err != nil {
		t.Fatal(err)
	}
	if cell := left.View.Cells[3*17+3]; cell.Glyph != '.' || cell.State != Explored {
		t.Fatalf("remembered floor = %+v", cell)
	}
	if contains(left.View, uint64(item)) {
		t.Fatal("item remained visible outside sight")
	}
}

func TestFailedMoveDoesNotChangeKnowledge(t *testing.T) {
	g := newStepGame(t)
	before := g.levels[1].KnownRows()
	result, err := g.Step(Command{Kind: CommandMove, DX: -1})
	if err != nil || result.Spent != 0 {
		t.Fatalf("blocked move: %+v %v", result, err)
	}
	if after := g.levels[1].KnownRows(); !reflect.DeepEqual(before, after) {
		t.Fatalf("blocked move changed map knowledge: %q -> %q", before, after)
	}
}

func TestStairTravelPreservesPerFloorKnowledge(t *testing.T) {
	g := newStepGame(t)
	firstBefore := g.levels[1].KnownRows()
	for _, row := range g.levels[2].KnownRows() {
		for _, cell := range row {
			if cell != ' ' {
				t.Fatal("unvisited floor already explored")
			}
		}
	}
	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}
	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}
	result, err := g.Step(Command{Kind: CommandDownstairs})
	if err != nil || result.View.LevelID != 2 {
		t.Fatalf("downstairs: %+v %v", result, err)
	}
	firstAfter := g.levels[1].KnownRows()
	for y, row := range firstBefore {
		for x := range row {
			if row[x] != ' ' && firstAfter[y][x] != row[x] {
				t.Fatal("first-floor knowledge lost")
			}
		}
	}
	second := g.levels[2].KnownRows()
	if second[1][1] != '<' {
		t.Fatal("destination stair not seen")
	}
	result, err = g.Step(Command{Kind: CommandUpstairs})
	if err != nil || result.View.LevelID != 1 {
		t.Fatalf("upstairs: %+v %v", result, err)
	}
	if !reflect.DeepEqual(second, g.levels[2].KnownRows()) {
		t.Fatal("inactive floor knowledge changed")
	}
}

func TestKnowledgeSaveRoundTrip(t *testing.T) {
	g := newStepGame(t)
	if _, err := g.Step(Command{Kind: CommandMove, DX: 1}); err != nil {
		t.Fatal(err)
	}
	snapshot := g.Snapshot()
	if snapshot.Version != 5 || len(snapshot.Levels) != 2 || len(snapshot.Levels[0].Known) == 0 {
		t.Fatalf("snapshot knowledge missing: %+v", snapshot.Levels)
	}
	restored, err := Restore(snapshot, testCatalog(t))
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
	if !reflect.DeepEqual(g.View(), restored.View()) || !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("restored sight or knowledge differs")
	}
}

func TestRestoreRejectsInvalidKnowledge(t *testing.T) {
	g := newStepGame(t)
	before := g.Snapshot()
	cases := []struct {
		name   string
		change func(*save.Snapshot)
	}{
		{"missing", func(s *save.Snapshot) { s.Levels[0].Known = nil }},
		{"short rows", func(s *save.Snapshot) { s.Levels[0].Known = s.Levels[0].Known[:1] }},
		{"short row", func(s *save.Snapshot) { s.Levels[0].Known[0] = s.Levels[0].Known[0][:2] }},
		{"long row", func(s *save.Snapshot) { s.Levels[0].Known[0] += " " }},
		{"bad glyph", func(s *save.Snapshot) {
			row := []byte(s.Levels[0].Known[0])
			row[0] = '?'
			s.Levels[0].Known[0] = string(row)
		}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			bad := g.Snapshot()
			tc.change(&bad)
			if replacement, err := Restore(bad, testCatalog(t)); err == nil {
				replacement.Close()
				t.Fatal("malformed knowledge restored")
			}
			if !reflect.DeepEqual(before, g.Snapshot()) {
				t.Fatal("failed restore changed live game")
			}
		})
	}
}
