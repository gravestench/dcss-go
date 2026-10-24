package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// Xom's item divination must mark a hidden floor item through the live Lua
// event path, expose it in the terminal view, and keep it across a save.
func TestXomDetectItemsMarksAndSavesHiddenFloorItem(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-divination")

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
	item := potionID(t, g)
	position, found := g.stores.Positions.Get(item)

	if !found {
		t.Fatal("fixture curing potion has no floor position")
	}

	position.X = 10
	position.Y = 1

	if err := level.MoveActor(g.player, 6, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	index := 1*level.width + 10

	if g.visible[index] || level.KnownCells()[1][10] != terrain.Unseen {
		t.Fatal("Xom item fixture must be hidden behind the central wall")
	}

	if _, err := g.scripts.Policy("test.xom_detect_items", nil); err != nil {
		t.Fatal(err)
	}

	if level.DetectedItems()[1][10] {
		t.Fatal("Xom detection marker committed before ApplyPending")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if !level.DetectedItems()[1][10] {
		t.Fatal("Xom did not mark the hidden item")
	}

	view := g.View()

	if !view.Cells[index].DetectedItem {
		t.Fatal("Xom's item marker is absent from the map view")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Xom's detected-item marker changed across save and restore")
	}
}

// A sensed monster is a saved map glyph rather than a visible actor. The
// detector may fuzz its coordinate, but the player must see the marker.
func TestXomDetectCreaturesSavesPerceptionWithoutRevealingActor(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-divination")

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
	var monster uint64

	for _, entity := range g.stores.Actors.Entities() {
		if entity != g.player {
			monster = uint64(entity)
			break
		}
	}

	if monster == 0 {
		t.Fatal("scenario has no monster to detect")
	}

	if err := level.MoveActor(akara.Entity(monster), 10, 1); err != nil {
		t.Fatal(err)
	}

	if err := level.MoveActor(g.player, 6, 1); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	index := 1*level.width + 10

	if g.visible[index] {
		t.Fatal("creature fixture must be hidden behind the central wall")
	}

	if _, err := g.scripts.Policy("test.xom_detect_creatures", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	var sensed bool

	for _, row := range level.DetectedCreatures() {
		for _, kindID := range row {
			sensed = sensed || kindID != ""
		}
	}

	if !sensed {
		t.Fatal("Xom created no sensed creature map marker")
	}

	view := g.View()
	var inView bool

	for _, cell := range view.Cells {
		inView = inView || cell.DetectedCreature
	}

	if !inView {
		t.Fatal("sensed creature is absent from the map view")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("sensed creature markers changed across save and restore")
	}
}
