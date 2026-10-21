package game

import (
	"reflect"
	"testing"

	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Put a source portal under the current player without deleting a linked
// stair. Generated Pan tests can then exercise real commands and ECS actors.
func placePortalForTest(t *testing.T, g *Game, feature terrain.ID) point {
	t.Helper()
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		t.Fatal("player has no position")
	}

	level := g.levels[position.LevelID]

	if level == nil {
		t.Fatal("player has no level")
	}

	if level.terrain[position.Y][position.X] == terrain.Floor {
		if err := level.SetCell(position.X, position.Y, feature); err != nil {
			t.Fatal(err)
		}

		return point{
			x: position.X,
			y: position.Y,
		}
	}

	for y, row := range level.Cells() {
		for x, current := range row {
			if current != terrain.Floor {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			if err := level.SetCell(x, y, feature); err != nil {
				t.Fatal(err)
			}

			return point{
				x: x,
				y: y,
			}
		}
	}

	t.Fatal("level has no floor for a Pan portal")

	return point{}
}

// Identify one generated Pan actor or floor item. It must die with its
// region rather than surviving as an invisible entity after transit.
func panFloorEntity(g *Game, levelID int) akara.Entity {
	for _, entity := range g.world.Entities() {
		if entity == g.player {
			continue
		}

		position, found := g.stores.Positions.Get(entity)

		if found && position.LevelID == levelID {
			return entity
		}
	}

	return 0
}

// An ordinary Pan exit searches around an occupied original portal. The
// blocker stays on Dungeon:1 and the player lands on a connected free cell.
func TestPanExitFindsSafeOriginalLanding(t *testing.T) {
	g := newGeneratedTestGame(t, 7405)
	health, _ := g.stores.Health.Get(g.player)

	health.Max = 10000
	health.Current = 10000

	origin := placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	oldID := g.panState.ActiveLevelID
	blocker := spawnWormForTest(t, g, 1)

	if err := g.levels[1].MoveActor(blocker, origin.x, origin.y); err != nil {
		t.Fatal(err)
	}

	placePortalForTest(t, g, terrain.ExitPandemonium)

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)

	if !found ||
		position.LevelID != 1 ||
		(position.X == origin.x && position.Y == origin.y) ||
		g.levels[oldID] != nil ||
		g.panState.ActiveLevelID != 0 {
		t.Fatalf("Pan exit did not use a safe landing: %+v %+v",
			position, g.panState)
	}

	actor, occupied := g.levels[1].ActorAt(origin.x, origin.y)

	if !occupied || actor != blocker {
		t.Fatal("Pan exit displaced the return-site blocker")
	}
}

// The downward Abyss gate retires Pan but preserves the Dungeon entry as
// the banishment return site, even across a save in the Abyss.
func TestPanAbyssExitPreservesOriginalReturn(t *testing.T) {
	g := newGeneratedTestGame(t, 7406)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000

	origin := placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	oldID := g.panState.ActiveLevelID
	placePortalForTest(t, g, terrain.ExitThroughAbyss)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := g.stores.Positions.Get(g.player)
	banishment := g.scripts.Components()["world.banishment"]

	if !found ||
		position.LevelID != 1000 ||
		g.levels[oldID] != nil ||
		g.panState.ActiveLevelID != 0 ||
		!banishment.Has(g.player) {
		t.Fatalf("Pan Abyss exit lost its destination or history: %+v %+v",
			position, g.panState)
	}

	saved, _ := banishment.Get(g.player)
	levelID, _ := saved.Get("origin_level_id")
	x, _ := saved.Get("origin_x")
	y, _ := saved.Get("origin_y")

	if levelID != int64(1) ||
		x != int64(origin.x) ||
		y != int64(origin.y) {
		t.Fatalf("Abyss return site = %v, %v, %v", levelID, x, y)
	}

	health.Max = originalMax
	health.Current = originalMax

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["world.banishment"].Has(
		restored.player) {
		t.Fatal("Abyss return site was lost on restore")
	}
}

// Two source transit gates make two fresh regions. The original portal and
// unique-map history survive a save before an exit returns to Dungeon.
func TestPanTwoTransitsSaveAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 7403)
	// This test measures travel and lifecycle, not low-level survival against
	// a fully populated late-game realm.
	health, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player has no health")
	}

	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000

	origin := placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	// The first generated region includes a random lord in this seed. Save
	// it before transit so its actor-owned profile has to survive restore.
	lordStore := g.scripts.Components()["monster.pan_lord"]
	var lord akara.Entity

	for _, entity := range g.world.Entities() {
		if lordStore.Has(entity) {
			lord = entity

			break
		}
	}

	if lord == 0 {
		t.Fatal("first Pan region has no actor-owned lord profile")
	}

	health.Max = originalMax
	health.Current = originalMax

	entryCopy, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if !entryCopy.scripts.Components()["monster.pan_lord"].Has(lord) {
		t.Fatal("Pan lord profile was lost on restore")
	}

	entryCopy.Close()

	health.Max = 10000
	health.Current = 10000

	for visit := 1; visit <= 2; visit++ {
		oldID := g.panState.ActiveLevelID
		oldEntity := panFloorEntity(g, oldID)

		if oldEntity == 0 {
			t.Fatal("Pan region has no populated entity")
		}

		placePortalForTest(t, g, terrain.TransitPandemonium)

		result, err := g.Step(Command{Kind: CommandUpstairs})

		if err != nil {
			t.Fatal(err)
		}

		if g.panState.ActiveLevelID == oldID ||
			g.panState.RegionsSeen != visit+1 ||
			g.levels[oldID] != nil ||
			g.world.EntityExists(oldEntity) {
			t.Fatalf("Pan transit %d: old=%d new=%d seen=%d oldLevel=%t oldEntity=%t spent=%d events=%+v",
				visit, oldID, g.panState.ActiveLevelID,
				g.panState.RegionsSeen, g.levels[oldID] != nil,
				g.world.EntityExists(oldEntity), result.Spent, result.Events)
		}
	}

	// Restore the player's legitimate maximum before snapshot validation.
	// Extra HP only keeps this portal-lifecycle test alive among late-game foes.
	health, _ = g.stores.Health.Get(g.player)
	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(restored.panState, g.panState) {
		t.Fatal("Pan history changed on restore")
	}

	activeID := restored.panState.ActiveLevelID
	placePortalForTest(t, restored, terrain.ExitPandemonium)

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := restored.stores.Positions.Get(restored.player)

	if !found ||
		position.LevelID != 1 ||
		position.X != origin.x ||
		position.Y != origin.y ||
		restored.panState.ActiveLevelID != 0 ||
		restored.levels[activeID] != nil {
		t.Fatalf("Pan exit did not return to its portal: %+v %+v",
			position, restored.panState)
	}
}
