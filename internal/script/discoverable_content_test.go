package script

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func TestOverlayAddsIndependentContentFiles(t *testing.T) {
	rules, err := modfs.Load("testdata/add-definitions")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	result, err := runtime.Policy("test.content", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["monster"] != "test moss" ||
		result["spell"] != "Test Spark" ||
		result["item"] != "test relic" ||
		result["item_class"] != "OBJ_TEST_RELICS" ||
		result["known_class"] != "OBJ_TEST_RELICS" ||
		result["moss_allowed"] != true ||
		result["moss_weight"] != int64(2520000) ||
		result["moss_hp"] != int64(25) {
		t.Fatalf("Lua catalog did not see added definitions: %+v", result)
	}

	scope, err := runtime.Policy(
		"magic.player_scope",
		map[string]any{"spell_id": "SPELL_TEST_SPARK"},
	)

	if err != nil {
		t.Fatal(err)
	}

	if scope["scope"] != "book" {
		t.Fatalf("added spell scope = %v", scope["scope"])
	}

	coverage, err := runtime.Policy("magic.effect_coverage", nil)

	if err != nil {
		t.Fatal(err)
	}

	switch missing := coverage["missing"].(type) {
	case []any:
		for _, id := range missing {
			if id == "SPELL_TEST_SPARK" {
				t.Fatal("added spell resolver was not discovered")
			}
		}

	case map[string]any:
		if len(missing) != 0 {
			t.Fatalf("unexpected spell coverage: %v", missing)
		}

	default:
		t.Fatalf("spell coverage returned %T", coverage["missing"])
	}

	for _, entry := range []struct {
		category string
		id       string
		name     string
	}{
		{
			category: "monsters",
			id:       "MONS_TEST_MOSS",
			name:     "test moss",
		},

		{
			category: "spells",
			id:       "SPELL_TEST_SPARK",
			name:     "Test Spark",
		},

		{
			category: "items",
			id:       "UNRAND_TEST_RELIC",
			name:     "test relic",
		},

		{
			category: "items",
			id:       "MY_MOD_TOKEN",
			name:     "test token",
		},

		{
			category: "items",
			id:       "MY_MOD_FUTURE_SPELL_ITEM",
			name:     "future spell token",
		},
	} {
		definition := runtime.definitions[entry.category][entry.id]

		if definition == nil {
			t.Fatalf("missing %s %s", entry.category, entry.id)
		}

		if got := definition.RawGetString("name"); got != lua.LString(entry.name) {
			t.Fatalf("%s %s name = %s, want %q", entry.category, entry.id, got, entry.name)
		}

		origin := runtime.definitionOrigins[entry.category][entry.id]

		if !strings.HasPrefix(origin, "content/"+entry.category+"/") {
			t.Fatalf("%s %s origin = %q", entry.category, entry.id, origin)
		}
	}

	custom := runtime.definitions["my_mod2"]["MY_MOD_CUSTOM"]

	if custom == nil ||
		custom.RawGetString("label") != lua.LString("custom catalog value") {
		t.Fatalf("custom mod catalog was not registered: %v", custom)
	}

	item := runtime.definitions["items"]["MY_MOD_FUTURE_SPELL_ITEM"]

	if item.RawGetString("spell_id") != lua.LString("SPELL_TEST_SPARK") {
		t.Fatalf("early item did not resolve later spell ID: %v", item)
	}
}

func TestLayeredDiscoveryAndRequire(t *testing.T) {
	rules, err := modfs.Load(
		"testdata/add-definitions",
		"testdata/layered-helper",
	)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	content, err := runtime.Policy("test.content", nil)

	if err != nil {
		t.Fatal(err)
	}

	marker, err := runtime.Policy("test.layer_marker", nil)

	if err != nil {
		t.Fatal(err)
	}

	if content["monster"] != "test moss" || marker["value"] != "second layer" {
		t.Fatalf("layered discovery or require failed: content=%v marker=%v", content, marker)
	}
}

func TestSamePathOverlayReplacesBundledDefinition(t *testing.T) {
	rules, err := modfs.Load("testdata/override-monster")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	id := "MONS_ABOMINATION_LARGE"
	definition := runtime.definitions["monsters"][id]

	if got := definition.RawGetString("name"); got != lua.LString("renamed abomination") {
		t.Fatalf("monster name = %s", got)
	}

	if origin := runtime.definitionOrigins["monsters"][id]; origin != "content/monsters/0001_mons_abomination_large.lua" {
		t.Fatalf("monster origin = %q", origin)
	}
}

func TestSamePathPopulationOverrideKeepsSourceOrder(t *testing.T) {
	const path = "content/monsters/0495_mons_rat.lua"

	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	source, err := bundled.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	const oldRarity = "rarity = 1000,"
	const newRarity = "rarity = 777,"

	if strings.Count(string(source), oldRarity) != 1 {
		t.Fatal("rat source population row changed")
	}

	root := t.TempDir()
	file := filepath.Join(root, filepath.FromSlash(path))

	if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
		t.Fatal(err)
	}

	changed := strings.Replace(string(source), oldRarity, newRarity, 1)

	if err := os.WriteFile(file, []byte(changed), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(root)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	definition := runtime.definitions["monsters"]["MONS_RAT"]
	rows, ok := definition.RawGetString("population").(*lua.LTable)

	if !ok {
		t.Fatal("population override lost rat rows")
	}

	row, ok := rows.RawGetInt(1).(*lua.LTable)

	if !ok {
		t.Fatalf("rat override row = %v", rows.RawGetInt(1))
	}

	if row.RawGetString("source_order") != lua.LNumber(2) {
		t.Fatalf("rat override source order = %v", row.RawGetString("source_order"))
	}

	if row.RawGetString("rarity") != lua.LNumber(777) {
		t.Fatalf("rat override row = %v", rows.RawGetInt(1))
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("population override did not change ruleset identity")
	}
}

func TestInvalidPlayerSpellScopeNamesContentFile(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-player-scope")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("invalid player scope was accepted")
	}

	if !strings.Contains(err.Error(), "zz_bad.lua") ||
		!strings.Contains(err.Error(), "player_scope") {
		t.Fatalf("invalid scope error omitted its source: %v", err)
	}
}

func TestDuplicateDefinitionReportsBothPaths(t *testing.T) {
	rules, err := modfs.Load("testdata/duplicate-monster")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("duplicate monster was accepted")
	}

	for _, path := range []string{
		"content/monsters/0001_mons_abomination_large.lua",
		"content/monsters/zz_duplicate_abomination.lua",
	} {
		if !strings.Contains(err.Error(), path) {
			t.Fatalf("duplicate error omitted %s: %v", path, err)
		}
	}
}

func TestInvalidContentReferenceNamesFileAndField(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-monster-reference")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("missing monster spellbook was accepted")
	}

	for _, wanted := range []string{
		"content/monsters/zz_invalid_book.lua",
		"spellbook_id MST_DOES_NOT_EXIST",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("validation error omitted %q: %v", wanted, err)
		}
	}
}

func TestEarlyIDImportChecksMissingDefinitionAfterDiscovery(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-early-reference")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("missing spell reference was accepted")
	}

	for _, wanted := range []string{
		"content/items/0000_missing_spell.lua",
		"missing spells ID SPELL_NOT_REAL",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("early reference error omitted %q: %v", wanted, err)
		}
	}
}

func TestSpawnableMonsterOverrideFailsAtBootWhenIncomplete(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-spawnable-monster")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("incomplete spawnable monster was accepted")
	}

	for _, wanted := range []string{
		"content/monsters/0495_mons_rat.lua",
		"requires energy as table",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("validation error omitted %q: %v", wanted, err)
		}
	}
}
