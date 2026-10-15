package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

func setFixtureTerrain(t *testing.T, g *Game, x, y int, glyph byte) {
	t.Helper()

	level := g.levels[1]
	row := []byte(level.terrain[y])

	row[x] = glyph
	level.terrain[y] = string(row)

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}
}

func TestExplicitDoorOpenCloseAndRestore(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '+')

	opened, err := g.Step(Command{Kind: CommandOpenDoor})

	if err != nil ||
		opened.Spent != 10 || g.levels[1].terrain[1][2] != '\'' {
		t.Fatalf("open door = %+v, %v, row %q", opened, err, g.levels[1].terrain[1])
	}

	closed, err := g.Step(Command{Kind: CommandCloseDoor})

	if err != nil ||
		closed.Spent != 10 || g.levels[1].terrain[1][2] != '+' {
		t.Fatalf("close door = %+v, %v, row %q", closed, err, g.levels[1].terrain[1])
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("closed door changed across save and restore")
	}
}

func TestExplicitDoorDirectionAndConnectedGroup(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '+')
	setFixtureTerrain(t, g, 2, 2, '+')

	choice, err := g.Step(Command{Kind: CommandOpenDoor})

	if err != nil ||
		choice.Spent != 0 ||
		!strings.Contains(choice.Events[0].Text, "direction") {
		t.Fatalf("ambiguous door = %+v, %v", choice, err)
	}

	opened, err := g.Step(Command{
		Kind: CommandOpenDoor,
		DX:   1,
	})

	if err != nil ||
		opened.Spent != 10 ||
		g.levels[1].terrain[1][2] != '\'' || g.levels[1].terrain[2][2] != '\'' {
		t.Fatalf("connected door = %+v, %v", opened, err)
	}

	closed, err := g.Step(Command{
		Kind: CommandCloseDoor,
		DX:   1,
	})

	if err != nil ||
		closed.Spent != 10 ||
		g.levels[1].terrain[1][2] != '+' || g.levels[1].terrain[2][2] != '+' {
		t.Fatalf("connected close = %+v, %v", closed, err)
	}
}

func TestClosingDoorPushesFloorItems(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '\'')

	itemID := potionID(t, g)
	position, _ := g.stores.Positions.Get(itemID)

	position.X = 2
	position.Y = 1

	secondID, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(secondID, ecs.Item{
		KindID:   "POT_MIGHT",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(secondID, ecs.Position{
		LevelID: 1,
		X:       2,
		Y:       1,
	}); err != nil {
		t.Fatal(err)
	}

	closed, err := g.Step(Command{Kind: CommandCloseDoor})

	if err != nil ||
		closed.Spent != 10 {
		t.Fatalf("close over item = %+v, %v", closed, err)
	}

	for _, entity := range []akara.Entity{
		itemID,
		secondID,
	} {
		pushed, _ := g.stores.Positions.Get(entity)

		if g.levels[1].terrain[1][2] != '+' ||
			(pushed.X == 2 &&
				pushed.Y == 1) ||
			!g.levels[1].Walkable(pushed.X, pushed.Y) {
			t.Fatalf("item %d was left in closed door at %+v", entity, pushed)
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("pushed items or door RNG changed across save and restore")
	}
}

func TestForcedDoorPushDoesNotAdvanceRNG(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '\'')

	for _, cell := range []point{
		{
			x: 3,
			y: 1,
		},

		{
			x: 1,
			y: 2,
		},

		{
			x: 2,
			y: 2,
		},

		{
			x: 3,
			y: 2,
		},
	} {
		setFixtureTerrain(t, g, cell.x, cell.y, '#')
	}

	itemID := potionID(t, g)
	position, _ := g.stores.Positions.Get(itemID)

	position.X = 2
	position.Y = 1

	before := g.Snapshot()

	result, err := g.Step(Command{Kind: CommandCloseDoor})
	position, _ = g.stores.Positions.Get(itemID)
	after := g.Snapshot()

	if err != nil ||
		result.Spent != 10 ||
		position.X != 1 ||
		position.Y != 1 {
		t.Fatalf("forced push = %+v, %v, item %+v", result, err, position)
	}

	_, hadDoorStream := before.RNG["door"]
	_, hasDoorStream := after.RNG["door"]

	if hadDoorStream != hasDoorStream ||
		before.RNG["door"] != after.RNG["door"] {
		t.Fatal("forced door push advanced the door RNG stream")
	}
}

func TestClosingDoorRejectsVisibleActorWithoutTime(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '\'')

	if err := g.levels[1].MoveActor(ratID(t, g), 2, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	result, err := g.Step(Command{Kind: CommandCloseDoor})
	after := g.Snapshot()

	before.Messages = after.Messages

	if err != nil ||
		result.Spent != 0 || !reflect.DeepEqual(before, after) {
		t.Fatalf("blocked door = %+v, %v", result, err)
	}
}

func TestClosingDoorRejectsJammedGroupWithoutTime(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	if err := level.MoveActor(ratID(t, g), 6, 1); err != nil {
		t.Fatal(err)
	}

	for _, cell := range []struct {
		x     int
		y     int
		glyph byte
	}{
		{
			x:     2,
			y:     1,
			glyph: '\'',
		},

		{
			x:     3,
			y:     1,
			glyph: '\'',
		},

		{
			x:     4,
			y:     1,
			glyph: '\'',
		},

		{
			x:     5,
			y:     1,
			glyph: '#',
		},

		{
			x:     3,
			y:     2,
			glyph: '#',
		},

		{
			x:     4,
			y:     2,
			glyph: '#',
		},

		{
			x:     5,
			y:     2,
			glyph: '#',
		},
	} {
		setFixtureTerrain(t, g, cell.x, cell.y, cell.glyph)
	}

	itemID := potionID(t, g)
	position, _ := g.stores.Positions.Get(itemID)

	*position = ecs.Position{
		LevelID: 1,
		X:       4,
		Y:       1,
	}

	before := g.Snapshot()

	result, err := g.Step(Command{
		Kind: CommandCloseDoor,
		DX:   1,
	})

	after := g.Snapshot()

	before.Messages = after.Messages

	if err != nil ||
		result.Spent != 0 ||
		!reflect.DeepEqual(before, after) ||
		level.terrain[1][4] != '\'' {
		t.Fatalf("jammed door = %+v, %v", result, err)
	}
}

func TestUnseenDoorBlockerConsumesTurnWithoutClosing(t *testing.T) {
	g := newStepGame(t)

	for x := 2; x <= 10; x++ {
		setFixtureTerrain(t, g, x, 1, '\'')
	}

	if err := g.levels[1].MoveActor(ratID(t, g), 10, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if g.visible[10+g.levels[1].width] {
		t.Fatal("the distant door blocker is visible")
	}

	result, err := g.Step(Command{
		Kind: CommandCloseDoor,
		DX:   1,
	})

	if err != nil ||
		result.Spent != 10 ||
		g.levels[1].terrain[1][2] != '\'' ||
		!strings.Contains(result.Events[0].Text, "Something is blocking") {
		t.Fatalf("unseen blocker = %+v, %v", result, err)
	}
}

func TestEarlierJammedDoorPreventsUnseenBlockerTurn(t *testing.T) {
	g := newStepGame(t)

	for x := 2; x <= 10; x++ {
		setFixtureTerrain(t, g, x, 1, '\'')
	}

	for x := 2; x <= 4; x++ {
		setFixtureTerrain(t, g, x, 2, '#')
	}

	itemID := potionID(t, g)
	position, _ := g.stores.Positions.Get(itemID)

	position.X = 3
	position.Y = 1

	if err := g.levels[1].MoveActor(ratID(t, g), 10, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	result, err := g.Step(Command{
		Kind: CommandCloseDoor,
		DX:   1,
	})

	before.Messages = g.Snapshot().Messages

	if err != nil ||
		result.Spent != 0 ||
		!strings.Contains(result.Events[0].Text, "jamming") ||
		!reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatalf("jam before unseen blocker = %+v, %v", result, err)
	}
}

func TestPlayerStandingInDoorCannotCloseGroup(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '\'')
	setFixtureTerrain(t, g, 3, 1, '\'')

	if err := g.levels[1].MoveActor(g.player, 2, 1); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	result, err := g.Step(Command{
		Kind: CommandCloseDoor,
		DX:   1,
	})

	after := g.Snapshot()

	before.Messages = after.Messages

	if err != nil ||
		result.Spent != 0 ||
		!strings.Contains(result.Events[0].Text, "thick-headed") ||
		!reflect.DeepEqual(before, after) {
		t.Fatalf("player in doorway = %+v, %v", result, err)
	}
}

func TestInvalidDoorTargetsDoNotSpendTimeOrRNG(t *testing.T) {
	g := newStepGame(t)
	setFixtureTerrain(t, g, 2, 1, '+')
	before := g.Snapshot()

	for _, command := range []Command{
		{
			Kind: CommandCloseDoor,
			DX:   1,
		},

		{
			Kind: CommandOpenDoor,
			DX:   2,
		},

		{
			Kind: CommandOpenDoor,
			DY:   1,
		},
	} {
		result, err := g.Step(command)

		if err != nil ||
			result.Spent != 0 {
			t.Fatalf("invalid door %+v = %+v, %v", command, result, err)
		}
	}

	after := g.Snapshot()

	before.Messages = after.Messages

	if !reflect.DeepEqual(before, after) {
		t.Fatal("invalid door action changed time, terrain, items, or RNG")
	}
}
