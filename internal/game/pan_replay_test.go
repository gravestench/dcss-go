package game

import (
	"bytes"
	"encoding/json"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"

	"github.com/gravestench/akara"
)

// Find a real rune item and its source placement record on the expected Pan
// primary. A named realm must not pass with a rune fabricated by test setup.
func authoredPanRune(t *testing.T, g *Game, level *Level,
	vaultID, runeID string) (akara.Entity, ecs.Position) {
	t.Helper()

	if level.VaultID() != vaultID {
		t.Fatalf("Pan selected %q, want %q", level.VaultID(), vaultID)
	}

	foundRecord := false

	for _, record := range level.VaultRecords() {
		if record.SourceID == vaultID && runeRecord(record, runeID) {
			foundRecord = true
		}
	}

	if !foundRecord {
		t.Fatalf("Pan primary %s has no %s record", vaultID, runeID)
	}

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, located := g.stores.Positions.Get(entity)

		if !located || position.LevelID != level.ID {
			continue
		}

		if item.KindID == runeID {
			return entity, *position
		}
	}

	t.Fatalf("Pan primary %s has no live %s item", vaultID, runeID)

	return 0, ecs.Position{}
}

// Pick an initial layout stream state whose source pressure and identity
// draws select one named lord. The portal, map, population, and pickup then
// run normally; no production selector or content declaration is replaced.
func selectPanLord(t *testing.T, g *Game, lordIndex int) {
	t.Helper()

	for state := uint64(0); state < 1000; state++ {
		probe := RestoreRNGStreams(g.rng.seed, map[string]uint64{
			"layout": state,
		})

		pressure, err := probe.Intn("layout", 20)

		if err != nil {
			t.Fatal(err)
		}

		identity, err := probe.Intn("layout", 4)

		if err != nil {
			t.Fatal(err)
		}

		if pressure == 0 && identity == lordIndex {
			g.rng.states["layout"] = state

			return
		}
	}

	t.Fatalf("no layout stream state selects Pan lord index %d", lordIndex)
}

// The four source lord realms must each create their own floor rune, then
// ordinary pickup must store that rune in the player component and save.
func TestPanNamedLordRunesFromPortalThroughPickup(t *testing.T) {
	cases := []struct {
		vaultID string
		runeID  string
	}{
		{
			vaultID: "evilmike_mnoleg_eyes",
			runeID:  "RUNE_MNOLEG",
		},

		{
			vaultID: "lom_lobon_st",
			runeID:  "RUNE_LOM_LOBON",
		},

		{
			vaultID: "cerebov",
			runeID:  "RUNE_CEREBOV",
		},

		{
			vaultID: "evilmike_gloorx_vloq_box",
			runeID:  "RUNE_GLOORX_VLOQ",
		},
	}

	for index, test := range cases {
		t.Run(test.vaultID, func(t *testing.T) {
			g := newGeneratedTestGame(t, 7403)
			selectPanLord(t, g, index)

			health, found := g.stores.Health.Get(g.player)

			if !found {
				t.Fatal("player has no health")
			}

			health.Max = 10000
			health.Current = health.Max
			placePortalForTest(t, g, terrain.EnterPandemonium)

			if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
				t.Fatal(err)
			}

			level := g.levels[g.panState.ActiveLevelID]
			_, position := authoredPanRune(t, g, level,
				test.vaultID, test.runeID)

			collectRune(t, g, level, position.X, position.Y, test.runeID)
		})
	}
}

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
	placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	placePortalForTest(t, g, terrain.TransitPandemonium)
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
	placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	oldID := g.panState.ActiveLevelID
	level := g.levels[oldID]
	runeEntity, _ := authoredPanRune(t, g, level,
		"lemuel_hellion_island", "RUNE_DEMONIC")

	placePortalForTest(t, g, terrain.TransitPandemonium)

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	if g.levels[oldID] != nil || g.world.EntityExists(runeEntity) {
		t.Fatal("old Pan region or its uncollected rune survived transit")
	}

	health.Max = originalMax
	health.Current = originalMax

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if restored.world.EntityExists(runeEntity) {
		t.Fatal("retired Pan rune reappeared after restore")
	}
}

// Carry a source-placed rune through normal pickup, two source portals,
// restore in a later region, and exit. This joins the DES hook, ECS floor
// item, saved player progress, repeated region generation, and return site.
func TestPanAuthoredRunePickupTransitsAndExit(t *testing.T) {
	g := newGeneratedTestGame(t, 7403)
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10000
	health.Current = 10000

	origin := placePortalForTest(t, g, terrain.EnterPandemonium)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	level := g.levels[g.panState.ActiveLevelID]
	_, position := authoredPanRune(t, g, level,
		"lemuel_hellion_island", "RUNE_DEMONIC")

	collectRune(t, g, level, position.X, position.Y, "RUNE_DEMONIC")

	// The helper restores ordinary HP for a valid save. Extra HP here only
	// keeps portal lifecycle independent of the late-game monster fight.
	health.Max = 10000
	health.Current = 10000

	for visit := 0; visit < 2; visit++ {
		oldID := g.panState.ActiveLevelID
		placePortalForTest(t, g, terrain.TransitPandemonium)

		if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
			t.Fatal(err)
		}

		if g.panState.ActiveLevelID == oldID || g.levels[oldID] != nil {
			t.Fatalf("Pan transit %d did not retire its old region", visit+1)
		}
	}

	health, _ = g.stores.Health.Get(g.player)
	health.Max = originalMax
	health.Current = originalMax

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	progress, found := restored.scripts.Components()["character.runes"].Get(
		restored.player)

	if !found {
		t.Fatal("Pan rune progress disappeared on restore")
	}

	collected, err := progress.Get("collected")

	if err != nil {
		t.Fatal(err)
	}

	collectedSet, okay := collected.(map[string]any)

	if !okay || collectedSet["RUNE_DEMONIC"] != true {
		t.Fatalf("restored Pan rune progress = %v", collected)
	}

	activeID := restored.panState.ActiveLevelID
	loadedHealth, _ := restored.stores.Health.Get(restored.player)

	loadedHealth.Max = 10000
	loadedHealth.Current = 10000

	placePortalForTest(t, restored, terrain.ExitPandemonium)

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	returned, found := restored.stores.Positions.Get(restored.player)

	if !found {
		t.Fatal("Pan rune carrier has no position after exit")
	}

	if returned.LevelID != 1 {
		t.Fatalf("Pan rune carrier exited to level %d", returned.LevelID)
	}

	if returned.X != origin.x || returned.Y != origin.y {
		t.Fatalf("Pan rune carrier did not exit at origin: %+v", returned)
	}

	if restored.levels[activeID] != nil {
		t.Fatal("Pan region survived its source exit")
	}

	if restored.panState.ActiveLevelID != 0 {
		t.Fatal("Pan region survived its source exit")
	}
}
