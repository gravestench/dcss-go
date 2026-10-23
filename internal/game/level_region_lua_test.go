package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/save"
	"crawl/internal/terrain"
	"crawl/internal/vault"
	"github.com/gravestench/akara"
)

// Run the region mutation from an actual Lua policy, then force a
// subsequent policy error to confirm pending terrain is discarded.
func TestLuaRegionMutationStagesAndDiscards(t *testing.T) {
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
	before := g.Snapshot()

	if _, err := g.scripts.Policy("test.region_stage", nil); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("staged Lua region changed the live game")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if g.levels[abyssStorageID].Cells()[2][2] != terrain.RockWall {
		t.Fatal("committed Lua region lost its typed terrain")
	}

	committed := g.Snapshot()

	if _, err := g.scripts.Policy("test.region_fail", nil); err == nil {
		t.Fatal("forced Lua error did not propagate")
	}

	if !reflect.DeepEqual(committed, g.Snapshot()) {
		t.Fatal("failed Lua region changed the saved game")
	}
}

// Pure Lua decisions commit their RNG draw on return. BeginAction may
// discard staged commands, but it must not rewind a completed decision.
func TestLuaRegionRandomDecisionSurvivesNextAction(t *testing.T) {
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
	before := g.rng.States()

	if _, err := g.scripts.Policy("test.region_rng_only", nil); err != nil {
		t.Fatal(err)
	}

	committed := g.rng.States()

	if reflect.DeepEqual(before, committed) {
		t.Fatal("successful Lua policy did not advance its named stream")
	}

	g.scripts.BeginAction()

	if !reflect.DeepEqual(committed, g.rng.States()) {
		t.Fatal("the next action rewound a completed Lua decision")
	}
}

// The host and Lua views of an actor permutation agree across the action
// barrier. Terrain and save data remain unchanged until that barrier.
func TestLuaRegionMovesActorAtCommit(t *testing.T) {
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

	// Keep the test on the neutral, record-free Abyss grid. Replacing an
	// ordinary Dungeon floor without copying its stair and vault metadata
	// would test a malformed plan rather than an actor permutation.
	if err := g.levels[1].RemoveActor(g.player); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[abyssStorageID].PlaceActor(g.player, 40, 35); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	position, _ := g.stores.Positions.Get(g.player)
	old := *position
	result, err := g.scripts.Policy("test.region_move_player", nil)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("staged region moved the live actor before commit")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.X == old.X && position.Y == old.Y {
		t.Fatal("region did not move the actor")
	}

	if position.X != int(result["x"].(int64)) ||
		position.Y != int(result["y"].(int64)) {
		t.Fatalf("actor moved to unexpected cell: %+v", position)
	}
}

// Shift policy starts from the full saved region, so an untouched plan
// must round-trip source records, memory, and terrain exactly.
func TestLuaRegionPlanRoundTrip(t *testing.T) {
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
	level := g.levels[abyssStorageID]

	if err := level.AddVaultRecord(vault.Record{
		Kind:     vault.KindSourceFeature,
		SourceID: "test_region",
		Identity: string(terrain.Floor),
		X:        2,
		Y:        2,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.MapCell(2, 2); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()

	if _, err := g.scripts.Policy("test.region_roundtrip", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	after := g.Snapshot()

	if !reflect.DeepEqual(before, after) {
		left := reflect.ValueOf(before.Levels)
		right := reflect.ValueOf(after.Levels)

		for index := 0; index < left.Len(); index++ {
			if left.Index(index).FieldByName("ID").Int() != abyssStorageID {
				continue
			}

			for field := 0; field < left.Index(index).NumField(); field++ {
				prior := left.Index(index).Field(field).Interface()
				next := right.Index(index).Field(field).Interface()

				if !reflect.DeepEqual(prior, next) {
					t.Logf("changed level field: %s",
						left.Index(index).Type().Field(field).Name)
				}
			}
		}

		t.Fatal("untouched region plan did not preserve saved level data")
	}
}

// A Lua policy sees its staged session record while the game snapshot
// changes only at the action barrier; errors discard it entirely.
func TestLuaRegionSessionStateTransaction(t *testing.T) {
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
	before := g.Snapshot()

	if _, err := g.scripts.Policy("test.region_session_stage", nil); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, g.Snapshot()) {
		t.Fatal("staged session state changed the saved game")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	committed := g.Snapshot()

	if committed.AbyssState == nil ||
		committed.AbyssState.WorldX != 1 {
		t.Fatal("Lua session state did not commit")
	}

	if _, err := g.scripts.Policy("test.region_session_fail", nil); err == nil {
		t.Fatal("forced session policy error did not propagate")
	}

	if !reflect.DeepEqual(committed, g.Snapshot()) {
		t.Fatal("failed session policy changed the saved state")
	}
}

// A first banishment uses the authored terrain and state policies at the
// same barrier, rather than moving into the neutral backing grid.
func TestLuaRegionFirstAbyssEntry(t *testing.T) {
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
	before := g.Snapshot()

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	staged := g.Snapshot()

	if !reflect.DeepEqual(before.Levels, staged.Levels) ||
		len(staged.Entities) < len(before.Entities) ||
		!reflect.DeepEqual(before.Entities,
			staged.Entities[:len(before.Entities)]) ||
		staged.AbyssState != nil {
		t.Fatal("first Abyss entry published terrain, existing entities, or state before the barrier")
	}

	// Akara allocates entity handles before commit. They carry no ECS
	// components until the action barrier publishes the Lua commands.
	for _, entity := range staged.Entities[len(before.Entities):] {
		entity.ID = 0

		if !reflect.DeepEqual(entity, save.EntityRecord{}) {
			t.Fatal("staged Abyss actor acquired components before the barrier")
		}
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.abyssState == nil ||
		position.LevelID != abyssStorageID ||
		len(g.abyssState.SampleQueue) == 0 {
		t.Fatal("first Abyss entry did not generate state and move player")
	}

	if reflect.DeepEqual(before.Levels, g.Snapshot().Levels) {
		t.Fatal("first Abyss entry left the neutral backing grid")
	}
}

// A credited XP threshold installs a live Abyss exit on the player cell.
// The ordinary stair command then uses the latest outside return site.
func TestAbyssXPExitReturnsToOutsideSite(t *testing.T) {
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
	outside, _ := g.stores.Positions.Get(g.player)
	returnSite := point{
		x: outside.X,
		y: outside.Y,
	}

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	g.abyssState.ExitXP = 1

	if _, err := g.scripts.Policy("test.abyss_xp_exit", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)
	feature := g.levels[abyssStorageID].Cells()[position.Y][position.X]

	if feature != terrain.ExitAbyss ||
		g.abyssState.ExitXP != 10 ||
		!g.abyssState.ExitSpawned {
		t.Fatal("credited XP did not place the source Abyss exit")
	}

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ = g.stores.Positions.Get(g.player)

	if position.LevelID != outside.LevelID ||
		position.X != returnSite.x || position.Y != returnSite.y {
		t.Fatal("XP exit did not return to the outside site")
	}
}

// A second banishment starts a fresh window and updates the outside
// destination. Old floor entities cannot remain in the replacement map.
func TestAbyssReentryUsesLatestOutsideSite(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	oldState := cloneAbyssState(g.abyssState)
	position, _ := g.stores.Positions.Get(g.player)

	if err := g.levels[abyssStorageID].SetCell(position.X,
		position.Y, terrain.ExitAbyss); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	outside := g.levels[1]
	position, _ = g.stores.Positions.Get(g.player)
	var landing point
	found := false

	for y := 1; y < 10 && !found; y++ {
		for x := 1; x < 10; x++ {
			_, occupied := outside.ActorAt(x, y)

			if outside.Walkable(x, y) && !occupied {
				landing = point{
					x: x,
					y: y,
				}

				found = true
				break
			}
		}
	}

	if !found {
		t.Fatal("outside floor has no second departure cell")
	}

	if err := outside.MoveActor(g.player, landing.x, landing.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if g.abyssState.ReturnSite == nil ||
		g.abyssState.ReturnSite.X != landing.x ||
		g.abyssState.ReturnSite.Y != landing.y ||
		g.abyssState.TerrainSeed == oldState.TerrainSeed {
		t.Fatal("Abyss reentry reused the prior origin or terrain seed")
	}

	// The direct policy fixture bypasses Step's normal level activation.
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
		t.Fatal("reentered Abyss changed across save and restore")
	}
}

// Same-depth Abyss teleportation replaces the visible window while
// preserving the outside origin and earned exit progress.
func TestAbyssTeleportCreatesFreshRegion(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	prior := cloneAbyssState(g.abyssState)

	g.abyssState.ExitXP = 4
	g.abyssState.ExitSpawned = true

	if _, err := g.scripts.Policy("test.abyss_teleport", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if g.abyssState.BranchDepth != prior.BranchDepth ||
		g.abyssState.TerrainSeed == prior.TerrainSeed ||
		g.abyssState.ExitXP != 4 ||
		!g.abyssState.ExitSpawned ||
		!reflect.DeepEqual(g.abyssState.ReturnSite, prior.ReturnSite) ||
		position.X != 40 || position.Y != 35 {
		t.Fatal("same-depth Abyss teleport lost its state or landing")
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
		t.Fatal("teleported Abyss changed across save and restore")
	}
}

// The next ordinary player action recenters a near-edge Abyss window.
// The saved procedural origin changes with the region and round-trips.
func TestAbyssShiftRunsDuringPlayerAction(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	level := g.levels[abyssStorageID]
	var edge point
	var found bool

	for y := 12; y < 58; y++ {
		if level.Walkable(11, y) {
			edge = point{
				x: 11,
				y: y,
			}

			found = true
			break
		}
	}

	if !found {
		t.Fatal("sampled Abyss has no safe left-edge cell")
	}

	if err := level.MoveActor(g.player, edge.x, edge.y); err != nil {
		t.Fatal(err)
	}

	before := cloneAbyssState(g.abyssState)
	oldFeature := level.Cells()[edge.y][edge.x]

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.X != 40 ||
		position.Y != 35 ||
		g.abyssState.ShiftCount != before.ShiftCount+1 ||
		g.abyssState.WorldX != before.WorldX-29 ||
		g.levels[abyssStorageID].Cells()[35][40] != oldFeature {
		t.Fatalf("Abyss action did not shift the preserved cell: position=%+v state=%+v", position, g.abyssState)
	}

	shiftedPhase := g.abyssState.Phase

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.abyssState.Phase <= shiftedPhase ||
		g.abyssState.BranchDepth != before.BranchDepth {
		t.Fatal("ordinary Abyss time did not advance the independent morph clock")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("shifted Abyss changed across save and restore")
	}
}

// Abyssal stairs change the branch depth without turning the exit into
// an ordinary linked Dungeon stair. The outside return site remains saved.
func TestAbyssalStairDescendsToFreshRegion(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	returnSite := *g.abyssState.ReturnSite
	level := g.levels[abyssStorageID]

	if err := level.SetCell(40, 35, terrain.AbyssalStair); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != abyssStorageID ||
		position.X != 40 ||
		position.Y != 35 ||
		g.abyssState.BranchDepth != 2 ||
		g.levels[abyssStorageID].LocalDepth != 2 ||
		*g.abyssState.ReturnSite != returnSite {
		t.Fatal("Abyssal stair lost its depth, landing, or return site")
	}

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("descended Abyss changed across save and restore")
	}
}

// At the source bottom depth, the rune chance reaches its cap. Its ECS
// item is unique on the active floor and ordinary pickup records it on
// the player, so future generation cannot create another copy.
func TestAbyssalRuneIsUniqueThroughDescentAndPickup(t *testing.T) {
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

	// Combat is outside this rune lifecycle test. Keep the player alive
	// across six depth changes so its final action truly shifts the map.
	health, _ := g.stores.Health.Get(g.player)
	originalMax := health.Max

	health.Max = 10_000
	health.Current = health.Max

	if _, err := g.scripts.Policy("test.region_enter_abyss", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	for depth := 2; depth <= 7; depth++ {
		if err := g.levels[abyssStorageID].SetCell(40, 35,
			terrain.AbyssalStair); err != nil {
			t.Fatal(err)
		}

		if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
			t.Fatal(err)
		}

		if g.abyssState.BranchDepth != depth {
			t.Fatalf("Abyss depth = %d, want %d", g.abyssState.BranchDepth, depth)
		}
	}

	var runeEntity uint64
	var runePosition point
	count := 0

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)
		position, positioned := g.stores.Positions.Get(entity)

		if item.KindID == "RUNE_ABYSSAL" &&
			positioned &&
			position.LevelID == abyssStorageID {
			count++
			runeEntity = uint64(entity)
			runePosition = point{
				x: position.X,
				y: position.Y,
			}
		}
	}

	if count != 1 {
		t.Fatalf("Abyss:7 has %d rune entities, want one", count)
	}

	// Source vault monsters may guard a rune. Move that guardian to a
	// free cell so this test can isolate ordinary item pickup behavior.
	level := g.levels[abyssStorageID]

	if guardian, occupied := level.ActorAt(runePosition.x,
		runePosition.y); occupied {
		moved := false

		for y := 1; y < 69 && !moved; y++ {
			for x := 1; x < 79; x++ {
				_, taken := level.ActorAt(x, y)

				if level.Walkable(x, y) && !taken {
					if err := level.MoveActor(guardian, x, y); err != nil {
						t.Fatal(err)
					}

					moved = true
					break
				}
			}
		}

		if !moved {
			t.Fatal("Abyss rune guardian has no relocation cell")
		}
	}

	if err := level.MoveActor(g.player,
		runePosition.x, runePosition.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandPickup}); err != nil {
		t.Fatal(err)
	}

	if g.world.EntityExists(akara.Entity(runeEntity)) {
		t.Fatal("picked up Abyssal rune still exists on the floor")
	}

	var edge point
	var found bool

	for y := 12; y < 58; y++ {
		if g.levels[abyssStorageID].Walkable(11, y) {
			edge = point{
				x: 11,
				y: y,
			}

			found = true
			break
		}
	}

	if !found {
		t.Fatal("Abyss:7 has no safe shift trigger cell")
	}

	if err := g.levels[abyssStorageID].MoveActor(g.player,
		edge.x, edge.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if g.abyssState.ShiftCount == 0 {
		t.Fatal("edge wait did not shift the Abyss window")
	}

	for _, entity := range g.stores.Items.Entities() {
		item, _ := g.stores.Items.Get(entity)

		if item.KindID == "RUNE_ABYSSAL" {
			t.Fatal("shift generated another Abyssal rune after pickup")
		}
	}

	// Restore the source-derived maximum before exercising save integrity.
	health.Max = originalMax
	health.Current = originalMax

	snapshot := g.Snapshot()
	restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("collected Abyssal rune changed across save and restore")
	}
}
