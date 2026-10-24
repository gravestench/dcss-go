package game

import (
	"encoding/json"
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
)

// A Xom action must move the live travel link and save both that location
// and the player's repulsion timer. Lua's focused proxy cannot verify the
// Go grid transaction or its restore path.
func TestXomMovedStairAndRepulsionSurviveSave(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-actions")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	level := g.levels[1]

	if err := level.MoveActor(g.player, 7, 5); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	result, err := g.scripts.Policy("test.xom_stairs", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["moved"] != int64(1) {
		t.Fatalf("Xom moved %v stairs, want one", result["moved"])
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	links := level.StairLinks()

	if len(links) != 1 ||
		links[0].X != 7 ||
		links[0].Y >= 3 {
		t.Fatalf("Xom moved stair to %+v", links)
	}

	if level.terrain[3][7] != terrain.Floor ||
		level.terrain[links[0].Y][links[0].X] != terrain.StairsDown {
		t.Fatal("Xom stair glyph and link diverged")
	}

	if !g.scripts.Components()["religion.xom_stair_repel"].Has(g.player) {
		t.Fatal("Xom repulsion timer was not stored on the player")
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Xom stair or repulsion state changed across restore")
	}

	// A forged duration must fail the same restore validation as other
	// lasting god state instead of extending the action indefinitely.
	for entityIndex := range snapshot.Entities {
		entity := &snapshot.Entities[entityIndex]

		if entity.ID != uint64(g.player) {
			continue
		}

		for componentIndex := range entity.Dynamic {
			state := &entity.Dynamic[componentIndex]

			if state.Schema == "religion.xom_stair_repel" {
				state.Values["move_aut"] = json.RawMessage("1001")
			}
		}
	}

	if _, err := RestoreWithRules(snapshot, rules, RestorePolicy{}); err == nil {
		t.Fatal("restore accepted an impossible Xom repulsion timer")
	}
}

// A timed Ossuary gate has a terrain glyph, a DES marker, and an ECS clock.
// Xom's stair action must move all three as one saved travel entrance.
func TestXomMovesTimedPortalWithClockAndMarker(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-actions")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		88132,
		"SP_HUMAN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	level := g.levels[1]

	placed := false

	for y := 2; y < len(level.terrain)-2 && !placed; y++ {
		for x := 2; x < level.width-2; x++ {
			clear := true

			for dy := -2; dy <= 2 && clear; dy++ {
				for dx := -2; dx <= 2; dx++ {
					if level.terrain[y+dy][x+dx] != terrain.Floor {
						clear = false
						break
					}
				}
			}

			if !clear {
				continue
			}

			if _, occupied := level.ActorAt(x, y); occupied {
				continue
			}

			if err := level.MoveActor(g.player, x, y); err != nil {
				t.Fatal(err)
			}

			placed = true
			break
		}
	}

	if !placed {
		t.Fatal("generated Dungeon has no open square for portal")
	}

	origin := placeOssuaryPortalForTest(t, g)
	store := g.scripts.Components()["world.ossuary_portal"]
	portals := store.Entities()

	if len(portals) != 1 {
		t.Fatalf("portal clock count = %d", len(portals))
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Policy("test.xom_stairs", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	clock, found := store.Get(portals[0])

	if !found {
		t.Fatal("Xom destroyed the timed portal clock")
	}

	xValue, _ := clock.Get("x")
	yValue, _ := clock.Get("y")
	x := int(xValue.(int64))
	y := int(yValue.(int64))

	if x == origin.x && y == origin.y {
		t.Fatal("Xom left the portal at its original cell")
	}

	if level.terrain[origin.y][origin.x] != terrain.Floor ||
		level.terrain[y][x] != terrain.EnterOssuary {
		t.Fatal("Xom moved the portal clock without its grid feature")
	}

	record := level.VaultRecords()[len(level.VaultRecords())-1]

	if record.X != x || record.Y != y {
		t.Fatal("Xom left the portal marker at its old cell")
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Xom's moved portal changed across save and restore")
	}

	// Once Xom's temporary climb interference ends, the new location must
	// open the same source Ossuary through the ordinary travel command.
	restored.scripts.Components()["religion.xom_stair_repel"].Remove(
		restored.player,
	)

	if err := restored.levels[1].MoveActor(restored.player, x, y); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, found := restored.stores.Positions.Get(restored.player)

	if !found || restored.levels[position.LevelID].BranchID !=
		"BRANCH_OSSUARY" {
		t.Fatalf("moved portal did not open Ossuary: %+v", position)
	}
}
