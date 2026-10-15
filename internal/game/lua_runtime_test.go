package game

import (
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
)

func TestFailedLuaActionDoesNotMoveActorOrChangeHealth(t *testing.T) {
	rules, err := modfs.Load("testdata/rollback-mod")

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

	position, _ := g.stores.Positions.Get(g.player)
	before := *position
	health, _ := g.stores.Health.Get(g.player)
	beforeHP := health.Current

	for _, direction := range [][2]int{
		{1, 0},
		{-1, 0},
		{0, 1},
		{0, -1},
	} {
		x := before.X + direction[0]
		y := before.Y + direction[1]
		level := g.levels[before.LevelID]

		if !level.Walkable(x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		_, err := g.runAction(g.player, ecs.Intent{
			Kind: ecs.IntentMove,
			DX:   direction[0],
			DY:   direction[1],
		}, 10, "player")

		if err == nil {
			t.Fatal("Lua action unexpectedly succeeded")
		}

		if !strings.Contains(err.Error(), "intentional rollback") {
			t.Fatalf("Lua action error = %v", err)
		}

		if *position != before ||
			health.Current != beforeHP {
			t.Fatalf("failed action changed position %+v or HP %d", position, health.Current)
		}

		actor, found := level.ActorAt(before.X, before.Y)

		if !found ||
			actor != g.player {
			t.Fatal("failed action removed player from original cell")
		}

		if _, found := level.ActorAt(x, y); found {
			t.Fatal("failed action occupied destination")
		}

		return
	}

	t.Fatal("test scenario has no open adjacent cell")
}

func TestInvalidLuaPolicyOutputDiscardsCreatedEntity(t *testing.T) {
	g := newRollbackGame(t)
	before := len(g.world.Entities())

	_, err := g.scripts.Policy("test.invalid_output", nil)

	if err == nil {
		t.Fatal("invalid Lua policy unexpectedly succeeded")
	}

	if !strings.Contains(err.Error(), "must return a table") {
		t.Fatalf("invalid Lua policy result = %v", err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if got := len(g.world.Entities()); got != before {
		t.Fatalf("invalid policy left %d entities, want %d", got, before)
	}
}

func TestMalformedLuaPresentationReportsErrorInView(t *testing.T) {
	rules, err := modfs.Load("testdata/bad-view-mod")

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

	view := g.View()
	last := view.Messages[len(view.Messages)-1]

	if !strings.Contains(last, "Lua presentation error") {
		t.Fatalf("malformed Lua view produced %q", last)
	}
}

func TestFailedLuaApplyRollsBackEarlierComponentChange(t *testing.T) {
	g := newRollbackGame(t)
	playerPosition, _ := g.stores.Positions.Get(g.player)
	playerHealth, _ := g.stores.Health.Get(g.player)
	originalHP := playerHealth.Current
	level := g.levels[playerPosition.LevelID]

	for _, direction := range [][2]int{
		{1, 0},
		{-1, 0},
		{0, 1},
		{0, -1},
	} {
		x := playerPosition.X + direction[0]
		y := playerPosition.Y + direction[1]

		if !level.Walkable(x, y) {
			continue
		}

		if _, occupied := level.ActorAt(x, y); occupied {
			continue
		}

		_, err := g.scripts.Policy("test.apply_failure", map[string]any{
			"level_id": level.ID,
			"x":        x,
			"y":        y,
		})

		if err != nil {
			t.Fatal(err)
		}

		blocker, err := g.world.CreateEntity()

		if err != nil {
			t.Fatal(err)
		}

		if err := level.PlaceActor(blocker, x, y); err != nil {
			t.Fatal(err)
		}

		err = g.scripts.ApplyPending()

		if err == nil {
			t.Fatal("invalid Lua apply unexpectedly succeeded")
		}

		if !strings.Contains(err.Error(), "would block actor") {
			t.Fatalf("Lua apply error = %v", err)
		}

		if playerHealth.Current != originalHP {
			t.Fatalf("failed apply changed player HP to %d", playerHealth.Current)
		}

		return
	}

	t.Fatal("test scenario has no open adjacent cell")
}

func newRollbackGame(t *testing.T) *Game {
	t.Helper()

	rules, err := modfs.Load("testdata/rollback-mod")

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

	t.Cleanup(func() {
		g.Close()
	})

	return g
}

func TestOverlaySystemRunsInGameAndSurvivesSave(t *testing.T) {
	rules, err := modfs.Load("testdata/turn-counter-mod")

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

	if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	checkLuaCounter(t, g, 1)

	snapshot := g.Snapshot()
	hasCounterSchema := slices.ContainsFunc(snapshot.LuaSchemas,
		func(schema save.LuaSchemaRecord) bool {
			return schema.Name == "mod.turns" && schema.Version == 1
		})

	if snapshot.RulesetHash != rules.Hash() ||
		!hasCounterSchema ||
		len(snapshot.RulesetFiles) != len(rules.Paths()) ||
		len(snapshot.RulesetChanges) != 2 {
		t.Fatalf("Lua save metadata missing: hash=%q schemas=%d files=%d changes=%d",
			snapshot.RulesetHash,
			len(snapshot.LuaSchemas),
			len(snapshot.RulesetFiles),
			len(snapshot.RulesetChanges))
	}

	path := filepath.Join(t.TempDir(), "lua-save.json")

	if err := save.Write(path, snapshot); err != nil {
		t.Fatal(err)
	}

	fromDisk, err := save.Read(path)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := RestoreWithRules(
		fromDisk,
		rules,
		RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	checkLuaCounter(t, loaded, 1)

	if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	checkLuaCounter(t, loaded, 2)

	overlay := t.TempDir()

	copyLuaDirectory(t, overlay, "testdata/turn-counter-mod")
	copyLuaDirectory(t, overlay, "testdata/turn-counter-changed")

	changed, err := modfs.Load(overlay)

	if err != nil {
		t.Fatal(err)
	}

	_, err = RestoreWithRules(
		snapshot,
		changed,
		RestorePolicy{},
	)

	if err == nil {
		t.Fatal("changed ruleset loaded silently")
	}

	if !strings.Contains(err.Error(), "systems/turns.lua") {
		t.Fatalf("changed ruleset loaded silently: %v", err)
	}

	reinterpreted, err := RestoreWithRules(
		snapshot,
		changed,
		RestorePolicy{
			AllowRulesetMismatch: true,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer reinterpreted.Close()

	checkLuaCounter(t, reinterpreted, 1)

	withExtraSchema := t.TempDir()

	copyLuaDirectory(t, withExtraSchema, "testdata/turn-counter-mod")
	copyLuaDirectory(t, withExtraSchema, "testdata/turn-counter-extra")

	extraRules, err := modfs.Load(withExtraSchema)

	if err != nil {
		t.Fatal(err)
	}

	withExtra, err := RestoreWithRules(
		snapshot,
		extraRules,
		RestorePolicy{
			AllowRulesetMismatch: true,
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer withExtra.Close()

	checkLuaCounter(t, withExtra, 1)

	extraSchemas := withExtra.Snapshot().LuaSchemas
	hasExtraSchema := slices.ContainsFunc(extraSchemas,
		func(schema save.LuaSchemaRecord) bool {
			return schema.Name == "mod.extra" && schema.Version == 1
		})

	if len(extraSchemas) != len(snapshot.LuaSchemas)+1 || !hasExtraSchema {
		t.Fatal("added Lua schema was not registered")
	}
}

func checkLuaCounter(t *testing.T, g *Game, want int64) {
	t.Helper()

	store := g.scripts.Components()["mod.turns"]
	component, found := store.Get(g.player)

	if !found {
		t.Fatal("player has no Lua turn counter")
	}

	value, err := component.Get("count")

	if err != nil {
		t.Fatal(err)
	}

	if value != want {
		t.Fatalf("Lua turn counter = %v, want %d: %v", value, want, err)
	}
}

// copyLuaDirectory assembles a test overlay from real Lua files. Later
// copies replace earlier files at the same relative path.
func copyLuaDirectory(t *testing.T, target, source string) {
	t.Helper()

	err := filepath.WalkDir(source, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}

		if entry.IsDir() {
			return nil
		}

		relative, err := filepath.Rel(source, path)

		if err != nil {
			return err
		}

		destination := filepath.Join(target, relative)

		if err := os.MkdirAll(filepath.Dir(destination), 0o700); err != nil {
			return err
		}

		data, err := os.ReadFile(path)

		if err != nil {
			return err
		}

		return os.WriteFile(destination, data, 0o600)
	})

	if err != nil {
		t.Fatal(err)
	}
}
