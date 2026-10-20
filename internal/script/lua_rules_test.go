package script

import (
	"context"
	"path"
	"strings"
	"testing"
	"time"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// Lua rules tests execute in the production VM with production schemas.
// The Go runner supplies isolation and reports the Lua assertion location.
func TestLuaRules(t *testing.T) {
	rules, err := modfs.Load("testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	for _, name := range rules.Paths() {
		if !strings.HasPrefix(name, "tests/") ||
			!strings.HasSuffix(name, "_test.lua") {
			continue
		}

		t.Run(path.Base(name), func(t *testing.T) {
			runLuaRule(t, rules, name)
		})
	}
}

func TestModJewelleryRule(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/mod-jewellery")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/jewellery_mod_test.lua")
	runLuaRule(t, rules, "tests/reflector_mod_test.lua")
}

// A mod can disable one bundled DES layout and add another without changing
// the Go loader or the Lua selector's source tables.
func TestLayoutMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/layout-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/layout_mod_test.lua")
}

func TestVaultDuplicateAlias(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/vault-duplicate-alias")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err == nil {
		runtime.Close()
		t.Fatal("duplicate effective vault alias passed catalog validation")
	}

	for _, expected := range []string{
		"ambiguous monsters name",
		"MONS_RAT",
		"MONS_TEST_DUPLICATE_ALIAS",
		"vaults/arrival/",
	} {
		if !strings.Contains(err.Error(), expected) {
			t.Fatalf("catalog diagnostic lacks %q: %v", expected, err)
		}
	}
}

func runLuaRule(t *testing.T, rules modfs.Ruleset, name string) {
	t.Helper()

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(
		t,
		world,
		rules,
		Services{
			Emit: func(string, string) {},
			Random: func(_ string, _ int) (int, error) {
				return 0, nil
			},
			RandomWord: func(string) uint64 {
				return 0
			},
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	module, err := runtime.runModule(name)

	if err != nil {
		t.Fatal(err)
	}

	table, ok := module.(*lua.LTable)

	if !ok {
		t.Fatalf("%s must return a test module", name)
	}

	run, ok := runtime.state.GetField(table, "run").(*lua.LFunction)

	if !ok {
		t.Fatalf("%s must have a named run function", name)
	}

	limitDuration := 5 * time.Second

	if name == "tests/arrival_placement_test.lua" {
		// Source connectivity visits all 337 arrivals on full-sized grids.
		limitDuration = 180 * time.Second
	} else if name == "tests/vault_population_all_test.lua" {
		limitDuration = 60 * time.Second
	} else if name == "tests/shop_vault_all_placement_test.lua" {
		// Each committed shop map is fitted and connected on a full grid.
		limitDuration = 60 * time.Second
	} else if name == "tests/temple_floor_test.lua" {
		// Every source Temple builds and decodes a full-sized live level.
		limitDuration = 60 * time.Second
	}

	limit, cancel := context.WithTimeout(context.Background(), limitDuration)
	defer cancel()

	runtime.state.SetContext(limit)
	err = runtime.state.CallByParam(lua.P{
		Fn:      run,
		NRet:    0,
		Protect: true,
	}, runtime.context)

	runtime.state.RemoveContext()

	if err != nil {
		runtime.DiscardPending()
		t.Fatal(err)
	}

	if err := runtime.ApplyPending(); err != nil {
		t.Fatal(err)
	}
}
