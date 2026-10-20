package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/save"
)

func TestLinkedStairsReachThirdFloorAndSurviveSave(t *testing.T) {
	g := newStepGame(t)
	third, err := NewLevel(3, fixtureCells([]string{
		"#####",
		"#<..#",
		"#...#",
		"#####",
	}), g.stores.Positions)

	if err != nil {
		t.Fatal(err)
	}

	third.BranchID = g.levels[2].BranchID
	g.levels[3] = third

	second := g.levels[2]

	second.terrain[3][3] = fixtureFeature('>')

	if err := second.AddStairLink(StairLink{
		X:         3,
		Y:         3,
		ToLevelID: 3,
		ToX:       1,
		ToY:       1,
	}); err != nil {
		t.Fatal(err)
	}

	if err := third.AddStairLink(StairLink{
		X:         1,
		Y:         1,
		ToLevelID: 2,
		ToX:       3,
		ToY:       3,
	}); err != nil {
		t.Fatal(err)
	}

	if err := validateStairLinks(g.levels); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].MoveActor(g.player, 7, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	if err := second.MoveActor(g.player, 3, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found || *position != (ecs.Position{
		LevelID: 3,
		X:       1,
		Y:       1,
	}) {
		t.Fatalf("third-floor arrival = %+v", position)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("stair graph changed across restore")
	}

	for _, run := range []*Game{
		g,
		restored,
	} {
		if _, err := run.Step(Command{Kind: CommandUpstairs}); err != nil {
			t.Fatal(err)
		}

		position, _ := run.stores.Positions.Get(run.player)

		if position.LevelID != 2 ||
			position.X != 3 || position.Y != 3 {
			t.Fatalf("return arrival = %+v", position)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("stair travel diverged after restore")
	}
}

func TestRestoreRejectsInvalidStairDestination(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	snapshot.Levels[0].Stairs[0].ToLevelID = 99

	if _, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "invalid destination") {
		t.Fatalf("invalid stair destination error = %v", err)
	}
}

func TestPendingStairResolvesToExactLanding(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.SetCell(3, 3, fixtureFeature('>')); err != nil {
		t.Fatal(err)
	}

	if err := level.AddStairLink(StairLink{
		X:         3,
		Y:         3,
		ToLevelID: 3,
		Pending:   true,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.ResolveStairLink(3, 3, 4, 5); err != nil {
		t.Fatal(err)
	}

	link, found := level.StairAt(3, 3)

	if !found ||
		link.Pending ||
		link.ToX != 4 ||
		link.ToY != 5 {
		t.Fatalf("resolved link = %+v, found %t", link, found)
	}

	if err := level.ResolveStairLink(3, 3, 6, 7); err == nil {
		t.Fatal("resolved a stair link twice")
	}
}

func TestPendingStairRejectsConflictingDestinationState(t *testing.T) {
	for _, testCase := range []struct {
		name string
		link StairLink
	}{
		{
			name: "no target level",
			link: StairLink{
				Pending: true,
			},
		},

		{
			name: "unavailable message",
			link: StairLink{
				Pending:     true,
				ToLevelID:   2,
				Unavailable: "blocked",
			},
		},

		{
			name: "destination coordinate",
			link: StairLink{
				Pending:   true,
				ToLevelID: 2,
				ToX:       1,
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			g := newStepGame(t)
			level := g.levels[1]

			if err := level.SetCell(3, 3, fixtureFeature('>')); err != nil {
				t.Fatal(err)
			}

			link := testCase.link

			link.X = 3
			link.Y = 3

			if err := level.AddStairLink(link); err == nil {
				t.Fatalf("accepted invalid pending stair %+v", link)
			}
		})
	}
}

func TestFixedScenarioRestoreRejectsForgedUnavailableStair(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()
	stair := &snapshot.Levels[0].Stairs[0]

	stair.ToLevelID = 0
	stair.ToX = 0
	stair.ToY = 0
	stair.Unavailable = "Dungeon:2 is unavailable."

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("fixed scenario accepted an unavailable stair")
	}
}

func TestRestoreRejectsMissingStairLink(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	snapshot.Levels[0].Stairs = nil

	if _, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "missing stair link") {
		t.Fatalf("missing stair link error = %v", err)
	}
}

func TestLevelAllowsMultipleStairsOfOneKind(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	level.terrain[3][3] = fixtureFeature('>')

	if err := level.AddStairLink(StairLink{
		X:         3,
		Y:         3,
		ToLevelID: 2,
		ToX:       1,
		ToY:       1,
	}); err != nil {
		t.Fatal(err)
	}

	if got := len(level.StairLinks()); got != 2 {
		t.Fatalf("stair count = %d, want 2", got)
	}

	if err := level.MoveActor(g.player, 3, 3); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != 2 ||
		position.X != 1 || position.Y != 1 {
		t.Fatalf("second down stair arrived at %+v", position)
	}

	if err := level.AddStairLink(StairLink{
		X:         3,
		Y:         3,
		ToLevelID: 2,
		ToX:       1,
		ToY:       1,
	}); err == nil {
		t.Fatal("duplicate stair link accepted")
	}
}

func TestOlderSaveVersionCannotLoseStairLinksSilently(t *testing.T) {
	g := newStepGame(t)
	snapshot := g.Snapshot()

	snapshot.Version = save.Version - 1

	if _, err := Restore(snapshot); err == nil ||
		!strings.Contains(err.Error(), "unsupported save version") {
		t.Fatalf("older save version error = %v", err)
	}
}
