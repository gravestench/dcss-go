package script

import (
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

	for _, entry := range []struct {
		category string
		id       string
		name     string
	}{
		{category: "monsters", id: "MONS_TEST_MOSS", name: "test moss"},
		{category: "spells", id: "SPELL_TEST_SPARK", name: "Test Spark"},
		{category: "items", id: "UNRAND_TEST_RELIC", name: "test relic"},
		{category: "items", id: "MY_MOD_TOKEN", name: "test token"},
		{category: "items", id: "MY_MOD_FUTURE_SPELL_ITEM", name: "future spell token"},
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
