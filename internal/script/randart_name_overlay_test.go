package script

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

// Replacing one name group by its relative path must leave every other
// source group available through the same effective Lua catalog.
func TestRandartNameGroupOverlay(t *testing.T) {
	const path = "content/randart_names/weapon.lua"
	const oldPhrase = "of @_power_or_anger_@"
	const newPhrase = "of the Modder"

	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	source, err := bundled.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if strings.Count(string(source), oldPhrase) != 1 {
		t.Fatal("source weapon name phrase changed")
	}

	root := t.TempDir()
	file := filepath.Join(root, filepath.FromSlash(path))

	if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
		t.Fatal(err)
	}

	changed := strings.Replace(string(source), oldPhrase, newPhrase, 1)

	if err := os.WriteFile(file, []byte(changed), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(root)

	if err != nil {
		t.Fatal(err)
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("name override did not change the ruleset hash")
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	if count := len(runtime.DefinitionIDs("randart_names")); count != 182 {
		t.Fatalf("effective name group count = %d", count)
	}

	definition := runtime.definitions["randart_names"]["weapon"]
	entries := definition.RawGetString("entries").(*lua.LTable)
	first := entries.RawGetInt(1).(*lua.LTable)
	phrase := first.RawGetString("text").String()

	if phrase != newPhrase {
		t.Fatalf("effective weapon phrase = %q", phrase)
	}
}
