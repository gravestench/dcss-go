package game

import (
	"reflect"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
)

// Find a saved stream state whose next coin flip divides a legal merged
// body. This controls only the slime rule, leaving all other game streams
// and the real monster scheduler in place.
func forceSlimeSplitRoll(t *testing.T, g *Game) {
	t.Helper()

	for candidate := uint64(0); candidate < 1000; candidate++ {
		probe := RestoreRNGStreams(g.rng.seed, map[string]uint64{
			"slime_creature": candidate,
		})
		roll, err := probe.Intn("slime_creature", 2)

		if err != nil {
			t.Fatal(err)
		}

		if roll == 0 {
			g.rng.states["slime_creature"] = candidate

			return
		}
	}

	t.Fatal("could not find a slime split roll")
}

// The production action runner must tolerate the acting monster's removal
// during its decision phase. The target remains scheduled as a larger body.
func TestSlimeCreatureMergeDismissesActingBody(t *testing.T) {
	g, source := newEndoplasmGame(t, false)
	level := g.levels[1]
	var site point
	found := false

	for y := 2; y < len(level.terrain)-2 && !found; y++ {
		for x := 2; x < len(level.terrain[y])-5; x++ {
			available := true

			for dy := -1; dy <= 1; dy++ {
				for dx := 0; dx <= 5; dx++ {
					if !level.Walkable(x+dx, y+dy) {
						available = false
					}

					if _, occupied := level.ActorAt(x+dx, y+dy); occupied {
						available = false
					}

					if _, linked := level.StairAt(x+dx, y+dy); linked {
						available = false
					}
				}
			}

			if available {
				site = point{x: x, y: y}
				found = true

				break
			}
		}
	}

	if !found {
		t.Fatal("no open cells for slime merge fixture")
	}

	if err := level.RemoveActor(source); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActor(source, site.x, site.y); err != nil {
		t.Fatal(err)
	}

	for _, y := range []int{site.y - 1, site.y + 1} {
		if err := level.SetCell(site.x+1, y, terrain.RockWall); err != nil {
			t.Fatal(err)
		}
	}

	target, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(target, ecs.Actor{
		KindID: "MONS_SLIME_CREATURE",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(target, ecs.Health{
		Current: 50,
		Max:     50,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(target, ecs.Combatant{}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.AI.Set(target, ecs.MonsterAI{
		Behavior: "seek",
		TargetX:  site.x + 5,
		TargetY:  site.y,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.MonsterEnergy.Set(target, ecs.MonsterEnergy{
		Points: 70,
	}); err != nil {
		t.Fatal(err)
	}

	if err := level.PlaceActor(target, site.x+1, site.y); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		target, map[string]any{
			"fixed_hp": int64(50),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["monster.slime_birth"].Set(
		source, map[string]any{
			"created_aut": int64(g.currentAut),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["monster.slime_birth"].Set(
		target, map[string]any{
			"created_aut": int64(g.currentAut),
		}); err != nil {
		t.Fatal(err)
	}

	actor, _ := g.stores.Actors.Get(source)
	ai, _ := g.stores.AI.Get(source)
	health, _ := g.stores.Health.Get(source)
	energy, _ := g.stores.MonsterEnergy.Get(source)

	actor.KindID = "MONS_SLIME_CREATURE"
	ai.Behavior = "seek"
	ai.TargetX = site.x + 5
	ai.TargetY = site.y
	health.Current = 70
	health.Max = 70
	energy.Points = 80

	if _, err := g.runAction(source, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.stores.Actors.Has(source) {
		t.Fatal("merged source actor survived")
	}

	if !g.stores.Actors.Has(target) {
		t.Fatal("merged survivor was removed")
	}

	merged, ok := g.scripts.Components()["monster.slime_blob"].Get(target)

	if !ok {
		t.Fatal("merged survivor has no blob size")
	}

	size, _ := merged.Get("size")
	reshaped, _ := merged.Get("reshaped_max")

	if size != int64(2) || reshaped != int64(120) {
		t.Fatalf("merged blob = size %v, max %v; want 2, 120",
			size, reshaped)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	// Feeding after combination can raise the body's maximum above its
	// original roll. Restore must accept the saved growth lineage.
	mergedHealth, _ := g.stores.Health.Get(target)
	mergedHealth.Current = 480
	mergedHealth.Max = 480

	if _, err := g.scripts.Components()["religion.jiyva_growth"].Set(
		target, map[string]any{
			"birth_max":       int64(120),
			"split_count":     int64(0),
			"born_from_split": false,
		}); err != nil {
		t.Fatal(err)
	}

	fedLoaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer fedLoaded.Close()
}

// A live scheduled monster divides into two saved ECS actors. Restore has
// to accept the extra body without treating it as a second roster spawn.
func TestSlimeCreatureSplitSchedulesAndRestores(t *testing.T) {
	g, entity := newEndoplasmGame(t, false)
	placePlayerBesideMonster(t, g, entity)

	actor, _ := g.stores.Actors.Get(entity)
	health, _ := g.stores.Health.Get(entity)
	energy, _ := g.stores.MonsterEnergy.Get(entity)

	actor.KindID = "MONS_SLIME_CREATURE"
	health.Max = 360
	health.Current = 135
	energy.Points = 80

	if _, err := g.scripts.Components()["monster.slime_blob"].Set(
		entity, map[string]any{
			"size": int64(3),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["monster.slime_birth"].Set(
		entity, map[string]any{
			"created_aut": int64(g.currentAut),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.jiyva_growth"].Set(
		entity, map[string]any{
			"birth_max":       int64(180),
			"split_count":     int64(0),
			"born_from_split": false,
		}); err != nil {
		t.Fatal(err)
	}

	forceSlimeSplitRoll(t, g)

	if _, err := g.runAction(entity, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentWait {
		t.Fatalf("split intent = %d, want wait", g.turn.ResolvedIntent)
	}

	if err := g.scheduler.Spend(entity, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	count := 0
	totalHP := 0

	for _, current := range g.stores.Actors.Entities() {
		body, ok := g.stores.Actors.Get(current)

		if !ok || body.KindID != "MONS_SLIME_CREATURE" {
			continue
		}

		count++
		life, _ := g.stores.Health.Get(current)
		totalHP += life.Current
	}

	if count != 2 || totalHP != 135 {
		t.Fatalf("split left %d bodies and %d total HP", count, totalHP)
	}

	snapshot := g.Snapshot()
	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot.Entities, loaded.Snapshot().Entities) ||
		!reflect.DeepEqual(snapshot.RNG, loaded.Snapshot().RNG) {
		t.Fatal("slime entities or RNG changed on save restore")
	}
}

// Restore checks a transformed body against the live slime HP roll while
// the original endoplasm still accounts for its roster slot.
func TestSlimeCreaturePolymorphUsesLiveHP(t *testing.T) {
	g, entity := newEndoplasmGame(t, false)
	actor, _ := g.stores.Actors.Get(entity)
	health, _ := g.stores.Health.Get(entity)

	actor.KindID = "MONS_SLIME_CREATURE"
	health.Current = 60
	health.Max = 60
	// This fixture changes the body directly, bypassing the production Lua
	// transition that would regenerate its persisted polymorph choices.
	g.scripts.Components()["monster.polymorph_set"].Remove(entity)

	if _, err := g.scripts.Components()["magic.monster_polymorph"].Set(
		entity, map[string]any{
			"original_kind_id": "MONS_ENDOPLASM",
		}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}

// Planerend starts at five blobs, but its summoned body may divide before
// expiry. Both surviving actors keep the spell origin through restore.
func TestPlanerendSlimeSplitRestores(t *testing.T) {
	g, entity := newEndoplasmGame(t, false)
	level := g.levels[1]
	found := false

	for y := 2; y < len(level.terrain)-2 && !found; y++ {
		for x := 2; x < len(level.terrain[y])-2; x++ {
			open := true

			for _, other := range g.stores.Actors.Entities() {
				if other == entity || other == g.player {
					continue
				}

				position, located := g.stores.Positions.Get(other)

				if located && position.LevelID == 1 &&
					abs(position.X-x) <= 7 && abs(position.Y-y) <= 7 {
					open = false
				}
			}

			for dy := -1; dy <= 1; dy++ {
				for dx := -1; dx <= 1; dx++ {
					if !level.Walkable(x+dx, y+dy) {
						open = false
					}
					if _, occupied := level.ActorAt(x+dx, y+dy); occupied {
						open = false
					}
				}
			}

			if !open {
				continue
			}

			if err := level.RemoveActor(entity); err != nil {
				t.Fatal(err)
			}
			if err := level.PlaceActor(entity, x, y); err != nil {
				t.Fatal(err)
			}

			found = true
			break
		}
	}

	if !found {
		t.Fatal("no open area for summoned slime")
	}

	actor, _ := g.stores.Actors.Get(entity)
	health, _ := g.stores.Health.Get(entity)
	energy, _ := g.stores.MonsterEnergy.Get(entity)

	actor.KindID = "MONS_SLIME_CREATURE"
	health.Current = 300
	health.Max = 300
	energy.Points = 80

	if _, err := g.scripts.Components()["monster.slime_blob"].Set(
		entity, map[string]any{
			"size": int64(5),
		}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["magic.summon"].Set(
		entity, map[string]any{
			"owner":           g.player,
			"source_category": "spells",
			"source_id":       "SPELL_PLANEREND",
			"expires_aut":     int64(g.currentAut + 100),
			"attitude":        "friendly",
		}); err != nil {
		t.Fatal(err)
	}

	forceSlimeSplitRoll(t, g)

	if _, err := g.runAction(entity, ecs.Intent{}, 10, "monster"); err != nil {
		t.Fatal(err)
	}

	blob, ok := g.scripts.Components()["monster.slime_blob"].Get(entity)

	if !ok {
		t.Fatal("Planerend body lost its blob state")
	}

	size, _ := blob.Get("size")

	if size != int64(3) {
		t.Fatalf("Planerend survivor size = %v, want 3 after split", size)
	}

	foundChild := false

	for _, candidate := range g.stores.Actors.Entities() {
		if candidate == entity ||
			!g.scripts.Components()["monster.slime_birth"].Has(candidate) {
			continue
		}

		childBlob, ok := g.scripts.Components()["monster.slime_blob"].Get(candidate)

		if !ok || !g.scripts.Components()["magic.summon"].Has(candidate) {
			continue
		}

		childSize, _ := childBlob.Get("size")
		foundChild = childSize == int64(2)
	}

	if !foundChild {
		t.Fatal("Planerend split left no summoned two-blob child")
	}

	if err := g.scheduler.Spend(entity, ecs.Intent{
		Kind: g.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()
}
