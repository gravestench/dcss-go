package game

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
)

func TestOverlaySystemRunsInGameAndSurvivesSave(t *testing.T) {
	rules, err := modfs.Load("testdata/turn-counter-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		testCatalog(t),
		testCatalog(t).Player(),
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

	if snapshot.RulesetHash != rules.Hash() ||
		len(snapshot.LuaSchemas) != 1 ||
		len(snapshot.RulesetFiles) != 3 ||
		len(snapshot.RulesetChanges) != 2 {
		t.Fatalf("Lua save metadata missing: %+v", snapshot)
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
		testCatalog(t),
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
		testCatalog(t),
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
		testCatalog(t),
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
		testCatalog(t),
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

	if len(withExtra.Snapshot().LuaSchemas) != 2 {
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
