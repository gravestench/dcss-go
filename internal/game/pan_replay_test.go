package game

import (
	"bytes"
	"encoding/json"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// A saved Pan region must carry enough history and RNG state to make the
// next transit identical to an uninterrupted run. This compares the whole
// resulting save, including map, population, lord traits, and entities.
func TestPanNextRegionDrawMatchesAfterRestore(t *testing.T) {
	g := newGeneratedTestGame(t, 7403)
	health, found := g.stores.Health.Get(g.player)

	if !found {
		t.Fatal("player has no health")
	}

	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000
	placePanPortal(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	placePanPortal(t, g, terrain.TransitPandemonium)
	health.Max = originalMax
	health.Current = originalMax

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	currentHealth, _ := g.stores.Health.Get(g.player)
	loadedHealth, _ := restored.stores.Health.Get(restored.player)

	currentHealth.Max = 10000
	currentHealth.Current = 10000
	loadedHealth.Max = 10000
	loadedHealth.Current = 10000

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	currentHealth.Max = originalMax
	currentHealth.Current = originalMax
	loadedHealth.Max = originalMax
	loadedHealth.Current = originalMax

	uninterrupted, err := json.Marshal(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	replayed, err := json.Marshal(restored.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if !bytes.Equal(uninterrupted, replayed) {
		t.Fatal("Pan next-region draw changed after save and restore")
	}
}

// An unclaimed floor rune belongs to its one-visit Pan region. Transit
// retires the item entity with the old grid, and a later save must not
// resurrect it on the next region.
func TestPanTransitRetiresUncollectedRune(t *testing.T) {
	g := newGeneratedTestGame(t, 7403)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000
	placePanPortal(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	oldID := g.panState.ActiveLevelID
	position, _ := g.stores.Positions.Get(g.player)
	rune, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Items.Set(rune, ecs.Item{
		KindID:   "RUNE_DEMONIC",
		Quantity: 1,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Positions.Set(rune, ecs.Position{
		LevelID: oldID,
		X:       position.X,
		Y:       position.Y,
	}); err != nil {
		t.Fatal(err)
	}

	placePanPortal(t, g, terrain.TransitPandemonium)

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	if g.levels[oldID] != nil || g.world.EntityExists(rune) {
		t.Fatal("old Pan region or its uncollected rune survived transit")
	}

	health.Max = originalMax
	health.Current = originalMax

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.world.EntityExists(rune) {
		t.Fatal("retired Pan rune reappeared after restore")
	}
}
