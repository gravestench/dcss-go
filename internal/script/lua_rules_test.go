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

// A sparse price kind joins the effective Lua policy set without changing
// source Trove logic or adding a Go payment handler.
func TestTroveModPrice(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/trove-price-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/trove_custom_price_test.lua")
}

// Desolation addons join the effective ruin pool, and a matching path
// replaces one whole-floor map without requiring any Go registry edits.
func TestDesolationSparseMods(t *testing.T) {
	for _, directory := range []string{
		"testdata/desolation-addon-mod",
		"testdata/desolation-replace-mod",
	} {
		t.Run(path.Base(directory), func(t *testing.T) {
			rules, err := modfs.Load("testdata/lua", directory)

			if err != nil {
				t.Fatal(err)
			}

			runLuaRule(t, rules, "tests/desolation_mod_test.lua")
		})
	}
}

// A sparse temporary-portal handler cannot silently replace an existing
// feature owner with a different file path.
func TestDuplicateTemporaryPortalHandler(t *testing.T) {
	rules, err := modfs.Load("testdata/lua",
		"testdata/duplicate-temporary-portal")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules,
		"tests/duplicate_temporary_portal_test.lua")
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

// A sparse mod adds a Snake end vault through DES discovery alone.
func TestSnakeEndMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/snake-end-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/snake_end_mod_test.lua")
}

// Sparse Snake entry and ordinary DES files join the effective source pools.
func TestSnakeVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/snake-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/snake_vault_mod_test.lua")
}

// A sparse layer can add an entrance, ordinary room, and ending to Lair.
func TestLairVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/lair-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/lair_vault_mod_test.lua")
}

// A sparse layer adds an Orc gate, ordinary room, and finale by discovery.
func TestOrcVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/orc-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/orc_vault_mod_test.lua")
}

// A sparse layer adds an Elf room and ending to the same source selectors.
func TestElfVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/elf-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/elf_vault_mod_test.lua")
}

// A sparse layer extends the source D:15 Depths gate pool by DES discovery.
func TestDepthsEntryMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/depths-entry-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/depths_entry_mod_test.lua")
}

// An effective mod layer can replace one encompassing map and add another
// without changing the source family selector or the Lua hook resolver.
func TestDepthsEncompassMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/depths-encompass-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/depths_encompass_mod_test.lua")
}

// A sparse mod adds one Bazaar map to the source weighted pool without
// editing the built-in catalog or changing the file-order draw contract.
func TestBazaarVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/bazaar-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/bazaar_vault_mod_test.lua")
}

// A sparse Sewer map joins the effective weighted catalog by directory,
// without a Go branch switch or changing the built-in source files.
func TestSewerVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/sewer-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/sewer_vault_mod_test.lua")
}

// A sparse Ossuary layout and same-path hook override share the effective
// VFS catalog used by normal portal generation.
func TestOssuaryVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/ossuary-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/ossuary_vault_mod_test.lua")
}

// A sparse themed child and a same-path Lua hook override use the same
// effective Bailey catalog as ordinary portal generation.
func TestBaileyVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/bailey-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/bailey_vault_mod_test.lua")
}

// A missing method in a same-path Bailey hook override is rejected at
// catalog validation, before the one-use outside gate can be spent.
func TestBaileyBrokenHookMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/bailey-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		defer runtime.Close()
	}

	if err == nil {
		_, err = runtime.runModule("tests/bailey_bad_hook_test.lua")
	}

	if err == nil {
		t.Fatal("broken Bailey hook was accepted")
	}

	if !strings.Contains(err.Error(), "decay") {
		t.Fatalf("broken Bailey hook was accepted: %v", err)
	}
}

// A broken same-path handler is diagnosed when the effective map is
// validated, before an entrance spends its one-time gate.
func TestOssuaryBrokenHookMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/ossuary-broken-hook-mod")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		defer runtime.Close()
	}

	if err == nil {
		_, err = runtime.runModule("tests/ossuary_bad_hook_test.lua")
	}

	if err == nil ||
		!strings.Contains(err.Error(), "loot_mix") {
		t.Fatalf("broken Ossuary hook was accepted: %v", err)
	}
}

// A Zot layer replaces one weighted source file and adds a discoverable
// ordinary map with a same-path Lua hook.
func TestZotVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/zot-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/zot_vault_mod_test.lua")
}

// Disabling the effective Hall closes Zot:5 despite another explicit map.
func TestZotHallDisabledMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/zot-hall-disabled-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/zot_hall_disabled_test.lua")
}

// A sparse Pan layer adds a primary and overrides one source hook by path.
func TestPanVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/pan-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/pan_vault_mod_test.lua")
}

// A sparse layer extends Spider entries, ordinary maps, and jumping helpers.
func TestSpiderVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/spider-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/spider_vault_mod_test.lua")
}

// Sparse maps add Swamp and Shoals entrances through the same effective
// DES catalog used by bundled source gates.
func TestWaterEntryMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/water-entry-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/water_entry_mod_test.lua")
}

// A sparse mod adds a Swamp end vault through the same DES discovery path.
func TestSwampEndMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/swamp-end-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/swamp_end_mod_test.lua")
}

// A sparse mod extends Spider's mandatory end pool through DES discovery.
func TestSpiderEndMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/spider-end-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/spider_end_mod_test.lua")
}

// A sparse mod extends Shoals' end pool through the same DES discovery path.
func TestShoalsEndMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/shoals-end-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/shoals_end_mod_test.lua")
}

// A sparse layer adds an ordinary Shoals map and its named Lua hook.
func TestShoalsVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/shoals-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/shoals_vault_mod_test.lua")
}

// A sparse layer adds an ordinary Swamp map and its named Lua hook.
func TestSwampVaultMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/swamp-vault-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/swamp_vault_mod_test.lua")
}

// A sparse mod replaces the authored Slime:5 DES map at the same path.
func TestSlimeEndMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/slime-end-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/slime_end_mod_test.lua")
}

// A sparse mod adds another authored Lair-to-Slime gate by DES path.
func TestSlimeEntryMod(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/slime-entry-mod")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/slime_entry_mod_test.lua")
}

// An overlay end map tests PLACE selection through the production catalog.
func TestLayoutPlaceSelection(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/layout-place")

	if err != nil {
		t.Fatal(err)
	}

	runLuaRule(t, rules, "tests/layout_place_selection_test.lua")
	runLuaRule(t, rules, "tests/des_composition_test.lua")
}

// Overflow altar maps are discovered from layered source-format DES files.
func TestOverflowAltarMod(t *testing.T) {
	base, err := modfs.Load("testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/lua", "testdata/overflow-altar-mod")

	if err != nil {
		t.Fatal(err)
	}

	if base.Hash() == modded.Hash() || modded.Vanilla() {
		t.Fatal("overflow altar overlay did not change ruleset identity")
	}

	runLuaRule(t, modded, "tests/overflow_altar_mod_test.lua")
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
	} else if name == "tests/wizlab_hooks_test.lua" {
		// Every Wizard Lab executes a full source-sized placement and decode.
		limitDuration = 60 * time.Second
	} else if name == "tests/wizlab_events_test.lua" {
		// Four live owners inspect their actual source map marker groups.
		limitDuration = 60 * time.Second
	} else if name == "tests/overflow_altar_all_placement_test.lua" {
		// Each committed overflow map fits and executes its source hooks.
		limitDuration = 60 * time.Second
	} else if name == "tests/vaults_primary_layouts_test.lua" {
		// Eleven full Vaults levels each place bounded source room attempts.
		limitDuration = 60 * time.Second
	} else if name == "tests/vaults_end_composition_test.lua" {
		// A seeded end-floor sweep also places every source quadrant once.
		limitDuration = 60 * time.Second
	} else if name == "tests/worley_cave_layouts_test.lua" {
		// Several full grids run the source noise sampler in one Lua test.
		limitDuration = 15 * time.Second
	} else if name == "tests/pan_all_placement_test.lua" {
		// Every active Pan map executes placement and any named source hooks.
		limitDuration = 60 * time.Second
	} else if name == "tests/sewer_source_catalog_test.lua" {
		// All 34 source maps execute hooks and full-grid placement in one test.
		limitDuration = 30 * time.Second
	} else if name == "tests/gauntlet_placement_test.lua" {
		// Ten source parents compose many arena helpers on full grids.
		limitDuration = 90 * time.Second
	} else if name == "tests/gauntlet_level_test.lua" {
		// A complete parent also decodes all arena records and route links.
		limitDuration = 30 * time.Second
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
