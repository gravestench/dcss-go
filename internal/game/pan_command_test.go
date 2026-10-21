package game

import (
	"testing"

	"crawl/internal/terrain"
)

// The ordinary downstairs command recognizes a source Pan arch through Lua
// preparation and keeps the generated destination pending until action time.
func TestPanEntryCommandPreparesPortal(t *testing.T) {
	g := newGeneratedTestGame(t, 7401)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]
	placed := false

	for y, row := range level.Cells() {
		for x, feature := range row {
			if feature != terrain.Floor {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.SetCell(x, y, terrain.EnterPandemonium); err != nil {
				t.Fatal(err)
			}

			placed = true
			break
		}

		if placed {
			break
		}
	}

	if !placed {
		t.Fatal("D:1 has no free floor for a Pan portal")
	}

	prepared, err := g.prepareScriptCommand(Command{
		Kind: CommandDownstairs,
	}, position)

	if err != nil {
		t.Fatal(err)
	}

	if !prepared.spendsTime || prepared.portal == nil {
		t.Fatal("Pan portal was not prepared as a timed travel action")
	}
}

// Entering a Pan arch spends a turn, installs its populated region, and
// records the Dungeon portal so a later exit can return to that cell.
func TestPanEntryTravel(t *testing.T) {
	g := newGeneratedTestGame(t, 7402)
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]

	for y, row := range level.Cells() {
		for x, feature := range row {
			if feature != terrain.Floor {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.SetCell(x, y, terrain.EnterPandemonium); err != nil {
				t.Fatal(err)
			}

			goto placed
		}
	}

	t.Fatal("D:1 has no free floor for a Pan portal")

placed:
	origin := *position
	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	arrived, found := g.stores.Positions.Get(g.player)

	if !found ||
		arrived.LevelID == origin.LevelID ||
		g.panState == nil ||
		g.panState.ActiveLevelID != arrived.LevelID {
		t.Fatalf("Pan entry did not travel: position=%+v state=%+v",
			arrived, g.panState)
	}

	if result.Spent == 0 ||
		g.panState.Return == nil ||
		g.panState.Return.LevelID != origin.LevelID ||
		g.panState.Return.X != origin.X ||
		g.panState.Return.Y != origin.Y {
		t.Fatalf("Pan entry lost time or origin: %+v %+v", result,
			g.panState)
	}
}
