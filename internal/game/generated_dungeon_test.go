package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/save"
	"crawl/internal/terrain"
)

func newGeneratedTestGame(t *testing.T, seed uint64) *Game {
	t.Helper()

	g, err := NewDungeonGame(seed, "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		_ = g.Close()
	})

	return g
}

// Move through real stair actions so each floor consumes the current RNG and
// gains the same parent links and population it would receive during play.
func descendGeneratedTo(t *testing.T, g *Game, lastDepth int) {
	t.Helper()

	for depth := 1; depth < lastDepth; depth++ {
		level := g.levels[depth]
		var down StairLink

		for _, link := range level.StairLinks() {
			if link.ToLevelID != depth+1 {
				continue
			}

			if actor, occupied := level.ActorAt(link.X, link.Y); occupied &&
				actor != g.player {
				continue
			}

			down = link

			break
		}

		if down.ToLevelID == 0 {
			t.Fatalf("Dungeon:%d has no open downward stair", depth)
		}

		if err := level.MoveActor(g.player, down.X, down.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil {
			t.Fatal(err)
		}

		if result.View.LevelID != depth+1 {
			t.Fatalf("Dungeon:%d descent = %+v, %v", depth, result.View, err)
		}
	}
}

func TestGeneratedDungeonBuildsSecondFloorOnDescent(t *testing.T) {
	g := newGeneratedTestGame(t, 41)

	if len(g.levels) != 2 || g.levels[2] != nil {
		t.Fatalf("startup built %d levels, want D:1 and Abyss", len(g.levels))
	}

	var down StairLink

	for _, link := range g.levels[1].StairLinks() {
		if link.Pending {
			down = link

			break
		}
	}

	if !down.Pending {
		t.Fatal("D:1 has no pending down stair")
	}

	if err := g.levels[1].MoveActor(g.player, down.X, down.Y); err != nil {
		t.Fatal(err)
	}

	result, err := g.Step(Command{Kind: CommandDownstairs})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.LevelID != 2 ||
		g.levels[2] == nil ||
		g.levels[3] != nil {
		t.Fatal("first descent did not build only D:2")
	}
}

func TestGeneratedDungeonUsesLiveLayoutRandomness(t *testing.T) {
	baseline := newGeneratedTestGame(t, 73)
	changed := newGeneratedTestGame(t, 73)

	if !reflect.DeepEqual(baseline.levels[1].Cells(), changed.levels[1].Cells()) {
		t.Fatal("same seed changed the startup floor")
	}

	// Ordinary play may consume the layout stream before the next stair. The
	// second floor must be built from that live state, not a startup cache.
	for range 32 {
		if _, err := changed.rng.Intn("layout", 1000); err != nil {
			t.Fatal(err)
		}
	}

	descendGeneratedTo(t, baseline, 2)
	descendGeneratedTo(t, changed, 2)

	if reflect.DeepEqual(baseline.levels[2].Cells(), changed.levels[2].Cells()) {
		t.Fatal("D:2 ignored the live layout RNG state")
	}
}

func TestGeneratedDungeonPlacesSecondFloorPotionsOnce(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 2)

	count := func() map[string]int {
		items := map[string]int{}

		for _, entity := range g.Snapshot().Entities {
			if entity.Position == nil ||
				entity.Position.LevelID != 2 ||
				entity.Item == nil {
				continue
			}

			items[entity.Item.KindID]++
		}

		return items
	}

	before := count()

	if before["POT_HEAL_WOUNDS"] == 0 || before["POT_HASTE"] == 0 {
		t.Fatal("D:2 is missing its starting potions")
	}

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(before, count()) {
		t.Fatal("returning to D:2 duplicated its starting items")
	}
}

// Keep the startup frontier and a later three-floor run for malformed-save
// cases. The save policy must accept only a contiguous Dungeon prefix.
func pendingDungeonPrefixSnapshot(t *testing.T) (save.Snapshot, save.Snapshot) {
	t.Helper()
	g := newGeneratedTestGame(t, 41)
	prefix := g.Snapshot()
	descendGeneratedTo(t, g, 3)
	full := g.Snapshot()

	return prefix, full
}

func TestGeneratedSaveAcceptsPendingDungeonFrontier(t *testing.T) {
	prefix, _ := pendingDungeonPrefixSnapshot(t)
	loaded, err := Restore(prefix)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(prefix, loaded.Snapshot()) {
		t.Fatal("pending Dungeon frontier changed across restore")
	}
}

func TestGeneratedSaveRejectsInvalidPendingDungeonFrontier(t *testing.T) {
	for _, testCase := range []struct {
		name   string
		mutate func(*save.Snapshot, save.Snapshot)
	}{
		{
			name: "missing middle floor",
			mutate: func(prefix *save.Snapshot, full save.Snapshot) {
				prefix.Levels = append(prefix.Levels, full.Levels[2])
			},
		},

		{
			name: "resolved stair to missing floor",
			mutate: func(prefix *save.Snapshot, _ save.Snapshot) {
				for index := range prefix.Levels[0].Stairs {
					stair := &prefix.Levels[0].Stairs[index]

					if stair.Pending {
						stair.Pending = false
						stair.ToX = 1
						stair.ToY = 1

						return
					}
				}
			},
		},

		{
			name: "pending stair to existing floor",
			mutate: func(prefix *save.Snapshot, full save.Snapshot) {
				prefix.Levels = full.Levels
				prefix.Entities = full.Entities

				for index := range prefix.Levels[0].Stairs {
					stair := &prefix.Levels[0].Stairs[index]

					if stair.ToLevelID == 2 {
						stair.Pending = true
						stair.ToX = 0
						stair.ToY = 0

						return
					}
				}
			},
		},

		{
			name: "pending stair skips a floor",
			mutate: func(prefix *save.Snapshot, _ save.Snapshot) {
				for index := range prefix.Levels[0].Stairs {
					stair := &prefix.Levels[0].Stairs[index]

					if stair.Pending {
						stair.ToLevelID = 3

						return
					}
				}
			},
		},

		{
			name: "pending stair has a destination coordinate",
			mutate: func(prefix *save.Snapshot, _ save.Snapshot) {
				for index := range prefix.Levels[0].Stairs {
					stair := &prefix.Levels[0].Stairs[index]

					if stair.Pending {
						stair.ToX = 1

						return
					}
				}
			},
		},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			prefix, full := pendingDungeonPrefixSnapshot(t)
			testCase.mutate(&prefix, full)

			if loaded, err := Restore(prefix); err == nil {
				loaded.Close()
				t.Fatal("accepted invalid generated Dungeon frontier")
			}
		})
	}
}

func TestNextFloorLuaPolicyPairsLiveParentStairs(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	parent := g.levels[1]
	stairs := []any{}
	var selected StairLink

	for _, link := range parent.StairLinks() {
		if link.ToLevelID != 2 {
			continue
		}

		stairs = append(stairs, map[string]any{
			"x":           link.X,
			"y":           link.Y,
			"pending":     true,
			"to_level_id": link.ToLevelID,
		})

		if selected.ToLevelID == 0 {
			selected = link
		}
	}

	if selected.ToLevelID == 0 {
		t.Fatal("D:1 has no downward stair")
	}

	result, err := g.scripts.Policy("world.generate_next_floor", map[string]any{
		"branch_id":         parent.BranchID,
		"local_depth":       2,
		"level_id":          2,
		"player_species_id": "SP_HUMAN",
		"player_name":       "Tester",
		"from_x":            selected.X,
		"from_y":            selected.Y,
		"branch_schedule":   luaBranchSchedule(g.branchSchedule),
		"parent": map[string]any{
			"id":          1,
			"branch_id":   parent.BranchID,
			"local_depth": parent.LocalDepth,
			"width":       parent.width,
			"height":      len(parent.terrain),
			"seen":        []any{},
			"stairs":      stairs,
		},
	})

	if err != nil {
		t.Fatal(err)
	}

	level, ok := result["level"].(map[string]any)

	if !ok {
		t.Fatal("next-floor policy returned no level")
	}

	cells, ok := level["cells"].([]any)

	if !ok || len(cells) != 70 {
		t.Fatalf("D:2 cell rows = %d", len(cells))
	}

	patches, ok := result["parent_links"].([]any)

	if !ok || len(patches) < len(stairs) {
		t.Fatalf("parent links = %d, want at least %d", len(patches), len(stairs))
	}

	entry, err := luaScenarioPoint(result["entry"])

	if err != nil {
		t.Fatal(err)
	}

	feature, err := luaScenarioCells(cells)

	if err != nil ||
		feature[entry.y][entry.x] != terrain.StairsUp {
		t.Fatalf("selected D:1 stair lands at %+v: %v", entry, err)
	}
}

func TestFirstFloorLuaPolicyLeavesFutureDungeonUngenerated(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	result, err := g.scripts.Policy("world.generate_first_floor", map[string]any{
		"player_species_id": "SP_HUMAN",
		"player_name":       "Tester",
	})

	if err != nil {
		t.Fatal(err)
	}

	levels, ok := result["levels"].([]any)

	if !ok || len(levels) != 2 {
		t.Fatalf("startup policy returned %d levels, want D:1 and Abyss",
			len(levels))
	}

	first, ok := levels[0].(map[string]any)

	if !ok || first["id"] != int64(1) {
		t.Fatalf("first generated level = %+v", levels[0])
	}

	items, ok := result["starting_items"].([]any)

	if !ok || len(items) != 1 {
		t.Fatalf("first-floor starting items = %d, want curing only",
			len(items))
	}
}

func TestGeneratedDungeonReachesDepthFifteen(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 15)

	if len(g.levels) != 16 {
		t.Fatalf("generated level count = %d, want Dungeon:1-15 and Abyss", len(g.levels))
	}

	for depth := 1; depth <= 15; depth++ {
		level := g.levels[depth]

		if level == nil {
			t.Fatalf("Dungeon:%d is missing", depth)
		}

		for _, stair := range level.StairLinks() {
			if stair.TargetBranchID != "" {
				continue
			}

			if stair.ToLevelID > 0 &&
				stair.ToLevelID != depth-1 &&
				stair.ToLevelID != depth+1 {
				t.Fatalf("Dungeon:%d has nonadjacent stair: %+v", depth, stair)
			}
		}
	}

	boundary := 0

	for _, stair := range g.levels[15].StairLinks() {
		if stair.Unavailable != "" {
			boundary++

			if !strings.Contains(stair.Unavailable, "Depths") {
				t.Fatalf("Dungeon:15 boundary = %q", stair.Unavailable)
			}
		}
	}

	if boundary < 3 {
		t.Fatalf("Dungeon:15 has %d Depths entrances, want at least 3", boundary)
	}
}

func TestGeneratedDungeonPopulatesOnFirstEntry(t *testing.T) {
	g := newGeneratedTestGame(t, 41)

	if g.levels[1].initialActors == 0 {
		t.Fatal("Dungeon:1 did not populate at startup")
	}

	if g.levels[2] != nil {
		t.Fatal("Dungeon:2 exists before first entry")
	}

	before := g.Snapshot()
	restored, err := Restore(before)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{g, restored} {
		var down StairLink

		for _, link := range run.levels[1].StairLinks() {
			if link.ToLevelID == 2 {
				down = link

				break
			}
		}

		if down.ToLevelID == 0 {
			t.Fatal("Dungeon:1 has no downward stair")
		}

		if err := run.levels[1].MoveActor(run.player, down.X, down.Y); err != nil {
			t.Fatal(err)
		}

		if _, err := run.Step(Command{Kind: CommandDownstairs}); err != nil {
			t.Fatal(err)
		}

		if run.levels[2].initialActors == 0 || run.levels[3] != nil {
			t.Fatal("first descent did not populate exactly Dungeon:2")
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("first-entry population changed across save/restore")
	}

	count := g.levels[2].initialActors

	if _, err := g.Step(Command{Kind: CommandUpstairs}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.Step(Command{Kind: CommandDownstairs}); err != nil {
		t.Fatal(err)
	}

	if g.levels[2].initialActors != count {
		t.Fatal("return to Dungeon:2 repeated initial population")
	}
}

func TestGeneratedDungeonFirstEntryThroughEveryDepth(t *testing.T) {
	g := newGeneratedTestGame(t, 41)

	for depth := 1; depth < 15; depth++ {
		var down StairLink

		for _, link := range g.levels[depth].StairLinks() {
			if link.ToLevelID != depth+1 {
				continue
			}

			if actor, occupied := g.levels[depth].ActorAt(link.X, link.Y); occupied &&
				actor != g.player {
				continue
			}

			down = link

			break
		}

		if down.ToLevelID == 0 {
			t.Fatalf("Dungeon:%d has no open downward stair", depth)
		}

		if err := g.levels[depth].MoveActor(g.player, down.X, down.Y); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})

		if err != nil ||
			result.View.LevelID != depth+1 {
			t.Fatalf("Dungeon:%d first descent = %+v, %v", depth, result.View, err)
		}

		if g.levels[depth+1].initialActors == 0 {
			t.Fatalf("Dungeon:%d remained unpopulated after entry", depth+1)
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("populated Dungeon changed after restoring at D:15")
	}
}

func TestGeneratedDungeonTopologyPopulationAndBoundary(t *testing.T) {
	g := newGeneratedTestGame(t, 41)
	descendGeneratedTo(t, g, 15)

	if len(g.levels) != 16 {
		t.Fatalf("generated level count = %d, want 16", len(g.levels))
	}

	vaultOrigins := g.scripts.Components()["vault.origin"]

	if vaultOrigins == nil {
		t.Fatal("vault origin component is unavailable")
	}

	vaultActors := 0

	for _, entity := range vaultOrigins.Entities() {
		if g.stores.AI.Has(entity) {
			vaultActors++
		}
	}

	// The population count excludes monsters placed by the selected vault.
	// Sorting catalog IDs can select a different vault for the same seed.
	expectedActors := vaultActors

	for depth := 1; depth <= 15; depth++ {
		expectedActors += g.levels[depth].initialActors
	}

	if len(g.stores.AI.Entities()) != expectedActors {
		t.Fatalf(
			"generated levels or monster counts are incomplete: levels=%d actors=%d expected=%d vault=%d",
			len(g.levels),
			len(g.stores.AI.Entities()),
			expectedActors,
			vaultActors,
		)
	}

	for depth := 1; depth <= 15; depth++ {
		level := g.levels[depth]

		if len(level.terrain) != 70 ||
			level.width != 80 ||
			len(level.StairLinks()) < 6 {
			t.Fatalf("Dungeon:%d topology is incomplete", depth)
		}

		for _, row := range level.terrain {
			if len(row) != 80 {
				t.Fatalf("Dungeon:%d has a short row", depth)
			}
		}

		maximum := 30

		if depth == 1 {
			maximum = 36
		}

		if count := level.initialMonsters; count < 3 || count > maximum {
			t.Fatalf("Dungeon:%d monster count = %d", depth, count)
		}
	}

	entryGame := newGeneratedTestGame(t, 41)
	position, _ := entryGame.stores.Positions.Get(entryGame.player)

	if fixtureGlyph(entryGame.levels[1].terrain[position.Y][position.X]) != '<' {
		t.Fatal("player did not start on an up stair")
	}

	before := entryGame.Snapshot()
	result, err := entryGame.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		result.Spent != 0 ||
		len(result.Events) != 1 ||
		!strings.Contains(result.Events[0].Text, "unavailable") {
		t.Fatalf("unported Dungeon exit = %+v, %v", result, err)
	}

	if !reflect.DeepEqual(before.RNG, entryGame.Snapshot().RNG) {
		t.Fatal("unavailable exit consumed randomness")
	}
}

func TestGeneratedDungeonSaveContinuation(t *testing.T) {
	g := newGeneratedTestGame(t, 73)
	sameSeed := newGeneratedTestGame(t, 73)

	if !reflect.DeepEqual(g.Snapshot(), sameSeed.Snapshot()) {
		t.Fatal("same seed produced a different Dungeon")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("generated terrain, stair links, or population changed on load")
	}

	for _, run := range []*Game{
		g,
		restored,
	} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("generated runs diverged after a turn")
	}
}

func TestGeneratedDungeonStairsTravelBetweenPairedCells(t *testing.T) {
	g := newGeneratedTestGame(t, 19)
	var stair StairLink

	for _, link := range g.levels[1].StairLinks() {
		if link.ToLevelID == 2 {
			stair = link

			break
		}
	}

	if stair.ToLevelID == 0 {
		t.Fatal("Dungeon:1 has no downward stair")
	}

	if err := g.levels[1].MoveActor(g.player, stair.X, stair.Y); err != nil {
		t.Fatal(err)
	}

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	down, err := g.Step(Command{Kind: CommandDownstairs})
	resolved, _ := g.levels[1].StairAt(stair.X, stair.Y)

	if err != nil ||
		down.View.LevelID != 2 ||
		down.View.PlayerX != resolved.ToX ||
		down.View.PlayerY != resolved.ToY {
		t.Fatalf("downward travel = %+v, %v", down.View, err)
	}

	up, err := g.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		up.View.LevelID != 1 ||
		up.View.PlayerX != stair.X ||
		up.View.PlayerY != stair.Y {
		t.Fatalf("upward travel = %+v, %v", up.View, err)
	}
}

func TestGeneratedDungeonStairsTravelToThirdFloor(t *testing.T) {
	g := newGeneratedTestGame(t, 19)

	for depth := 1; depth <= 2; depth++ {
		var downward StairLink

		for _, link := range g.levels[depth].StairLinks() {
			if link.ToLevelID == depth+1 {
				downward = link

				break
			}
		}

		if downward.ToLevelID == 0 {
			t.Fatalf("Dungeon:%d has no downward stair", depth)
		}

		if err := g.levels[depth].MoveActor(g.player, downward.X, downward.Y); err != nil {
			t.Fatal(err)
		}

		if err := g.refreshVisibility(); err != nil {
			t.Fatal(err)
		}

		result, err := g.Step(Command{Kind: CommandDownstairs})
		resolved, _ := g.levels[depth].StairAt(downward.X, downward.Y)

		if err != nil ||
			result.View.LevelID != depth+1 ||
			result.View.PlayerX != resolved.ToX ||
			result.View.PlayerY != resolved.ToY {
			t.Fatalf("Dungeon:%d downward travel = %+v, %v", depth, result.View, err)
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	result, err := restored.Step(Command{Kind: CommandUpstairs})

	if err != nil ||
		result.View.LevelID != 2 {
		t.Fatalf("restored Dungeon:3 ascent = %+v, %v", result.View, err)
	}
}

func TestWalkingIntoClosedDoorOpensAndSavesIt(t *testing.T) {
	g := newStepGame(t)
	level := g.levels[1]

	level.terrain[1][2] = fixtureFeature('+')
	level.terrain[1][3] = fixtureFeature('+')
	level.remembered[1*level.width+4] = ""

	if err := g.refreshVisibility(); err != nil {
		t.Fatal(err)
	}

	blocked := g.View().Cells[1*level.width+4]

	if blocked.State != Unknown {
		t.Fatalf("closed door leaked sight: %+v", blocked)
	}

	result, err := g.Step(Command{
		Kind: CommandMove,
		DX:   1,
	})

	if err != nil ||
		result.Spent != 10 ||
		result.View.PlayerX != 1 ||
		fixtureGlyph(level.terrain[1][2]) != '\'' ||
		fixtureGlyph(level.terrain[1][3]) != '\'' {
		t.Fatalf("opening by movement = %+v, %v", result, err)
	}

	if result.View.Cells[1*level.width+4].State != Visible {
		t.Fatal("sight did not pass through the open door")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("open door or map knowledge changed on load")
	}
}

func TestGeneratedDungeonRejectsInvalidSavedBoundaryAndBudget(t *testing.T) {
	g := newGeneratedTestGame(t, 17)
	snapshot := g.Snapshot()

	snapshot.Levels[0].InitialMonsters = 0

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted a generated level without its initial monster count")
	}

	snapshot = g.Snapshot()

	for index := range snapshot.Levels[0].Stairs {
		stair := &snapshot.Levels[0].Stairs[index]

		if stair.Unavailable != "" {
			stair.Unavailable = ""

			break
		}
	}

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted an unlinked generated exit")
	}

	descendGeneratedTo(t, g, 2)
	snapshot = g.Snapshot()

	for _, stair := range snapshot.Levels[0].Stairs {
		if stair.ToLevelID != 2 {
			continue
		}

		for index := range snapshot.Levels {
			if snapshot.Levels[index].ID == 2 {
				snapshot.Levels[index].Cells[stair.ToY][stair.ToX] = terrain.StairsDown

				break
			}
		}

		break
	}

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted a downward stair paired with another downward stair")
	}

	snapshot = g.Snapshot()
	snapshot.Levels[1].SpawnExclusions = append(
		snapshot.Levels[1].SpawnExclusions,
		save.PointRecord{
			X: 80,
			Y: 1,
		},
	)

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted an out-of-bounds saved spawn exclusion")
	}

	snapshot = g.Snapshot()
	snapshot.Levels[1].SpawnExclusions = append(
		snapshot.Levels[1].SpawnExclusions,
		save.PointRecord{
			X: 1,
			Y: 1,
		},
		save.PointRecord{
			X: 1,
			Y: 1,
		},
	)

	if _, err := Restore(snapshot); err == nil {
		t.Fatal("accepted duplicate saved spawn exclusions")
	}
}

func TestGeneratedDungeonBuildsAcrossSeeds(t *testing.T) {

	for seed := uint64(1); seed <= 16; seed++ {
		g, err := NewDungeonGame(seed, "SP_HUMAN", "JOB_FIGHTER", "WPN_RAPIER", "Tester")

		if err != nil {
			t.Fatalf("seed %d: %v", seed, err)
		}

		restored, err := Restore(g.Snapshot())

		if err != nil {
			t.Fatalf("seed %d restore: %v", seed, err)
		}

		_ = restored.Close()

		_ = g.Close()
	}
}
