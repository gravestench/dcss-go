package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/modfs"
	"crawl/internal/terrain"
	"github.com/gravestench/akara"
)

// A monster banished before the player arrives belongs to the Abyss,
// even when the player's first generated window discards its old cell.
// The same ECS identity must survive save and restore, whether the
// source's arrival coin puts it on this window or keeps it in transit.
func TestAbyssBanishedMonsterSurvivesFirstEntry(t *testing.T) {
	rules, err := modfs.Load("testdata/region-mod")

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
	var banishedID uint64

	for _, actor := range g.stores.AI.Entities() {
		position, positioned := g.stores.Positions.Get(actor)

		if positioned && position.LevelID == 1 {
			banishedID = uint64(actor)
			break
		}
	}

	if banishedID == 0 {
		t.Fatal("fixed D:1 has no monster to banish")
	}

	for _, policy := range []string{
		"test.abyss_banish_monster",
		"test.region_enter_abyss",
	} {
		if _, err := g.scripts.Policy(policy, nil); err != nil {
			t.Fatal(err)
		}

		if err := g.scripts.ApplyPending(); err != nil {
			t.Fatal(err)
		}
	}

	if !g.world.EntityExists(akara.Entity(banishedID)) {
		t.Fatal("banished monster was destroyed on first Abyss entry")
	}

	position, positioned := g.stores.Positions.Get(akara.Entity(banishedID))

	if !positioned ||
		(position.LevelID != abyssStorageID &&
			position.LevelID != abyssTransitID) {
		t.Fatal("banished monster has no Abyss or transit position")
	}

	if position.LevelID == abyssTransitID &&
		(len(g.abyssState.Transit) != 1 ||
			g.abyssState.Transit[0].EntityID != banishedID) {
		t.Fatal("parked monster is missing from the transit ledger")
	}

	if err := g.activateTransition(1, abyssStorageID, g.currentAut); err != nil {
		t.Fatal(err)
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
		t.Fatal("banished monster changed across Abyss save and restore")
	}
}

// A generated Dungeon floor past the fixed D:1-2 scenario is a valid
// outside departure. Save validation must accept its retained return site.
func TestAbyssDeepDungeonOriginRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/region-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	descendGeneratedTo(t, g, 3)

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatalf("restore from D:3 banishment: %v", err)
	}

	defer restored.Close()
}

// The keyed feature used by outside DES maps is a real, unlinked arch.
// It enters the same Abyss owner and returns to its exact source floor.
func TestAbyssEntranceArchEntersAndReturns(t *testing.T) {
	g := newGeneratedTestGame(t, 411)
	origin := placePortalForTest(t, g, terrain.EnterAbyss)

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != abyssStorageID {
		t.Fatalf("Abyss arch entered level %d", position.LevelID)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	position, _ = restored.stores.Positions.Get(restored.player)

	if err := restored.levels[abyssStorageID].SetCell(
		position.X, position.Y, terrain.ExitAbyss); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = restored.stores.Positions.Get(restored.player)

	if position.LevelID != 1 ||
		position.X != origin.x ||
		position.Y != origin.y {
		t.Fatalf("Abyss return = %+v, want D:1 (%d,%d)",
			position, origin.x, origin.y)
	}
}

// Depths:3 gives the source chance family a guaranteed draw. Its keyed
// entrance must become a live arch that uses the same return contract.
func TestDepthsAuthoredAbyssEntrance(t *testing.T) {
	rules, err := modfs.Load("testdata/abyss-travel-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(41,
		"SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester", rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	descendGeneratedTo(t, g, 15)

	parent := g.levels[15]

	for _, link := range parent.StairLinks() {
		if link.TargetBranchID == "BRANCH_DEPTHS" {
			moveGeneratedPlayerToStair(t, g, parent, link)
			break
		}
	}

	depths := followBranch(t, g, parent, "BRANCH_DEPTHS")
	depths = descendBranch(t, g, depths, 2)
	depths = descendBranch(t, g, depths, 3)
	authored := false

	for _, id := range depths.VaultIDs() {
		if strings.HasPrefix(id, "abyss_entry") {
			authored = true
		}
	}

	if !authored {
		t.Fatalf("Depths:3 did not select an Abyss entry map: %v",
			depths.VaultIDs())
	}

	var gate *point

	for y, row := range depths.Cells() {
		for x, feature := range row {
			if feature == terrain.EnterAbyss {
				gate = &point{
					x: x,
					y: y,
				}

				break
			}
		}

		if gate != nil {
			break
		}
	}

	if gate == nil {
		t.Fatalf("Depths:3 has no authored Abyss gate: %v",
			depths.VaultIDs())
	}

	moveGeneratedPlayerToStair(t, g, depths, StairLink{
		X: gate.x,
		Y: gate.y,
	})

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != abyssStorageID {
		t.Fatalf("authored gate entered level %d", position.LevelID)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	position, _ = restored.stores.Positions.Get(restored.player)

	if err := restored.levels[abyssStorageID].SetCell(
		position.X, position.Y, terrain.ExitAbyss); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = restored.stores.Positions.Get(restored.player)

	if position.LevelID != depths.ID ||
		position.X != gate.x || position.Y != gate.y {
		t.Fatalf("authored gate returned to %+v, want %d (%d,%d)",
			position, depths.ID, gate.x, gate.y)
	}
}

// Restore must reject two physical Abyssal runes before pickup can grant
// the same unique progress twice.
func TestRestoreRejectsDuplicateAbyssRunes(t *testing.T) {
	rules, err := modfs.Load("testdata/region-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	for count := 0; count < 2; count++ {
		entity, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		g.noteEntity(entity)

		if _, err := g.stores.Items.Set(entity, ecs.Item{
			KindID:   "RUNE_ABYSSAL",
			Quantity: 1,
		}); err != nil {
			t.Fatal(err)
		}

		if _, err := g.stores.Positions.Set(entity, *position); err != nil {
			t.Fatal(err)
		}
	}

	_, err = RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err == nil ||
		!strings.Contains(err.Error(), "saved Abyssal rune conflicts") {
		t.Fatalf("duplicate Abyssal runes restored: %v", err)
	}
}
