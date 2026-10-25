package script

import (
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

func TestDefinitionReturnsDetachedEffectiveLuaContent(t *testing.T) {
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

	definition, err := runtime.Definition("monsters", "MONS_TEST_MOSS")

	if err != nil {
		t.Fatal(err)
	}

	if definition["name"] != "test moss" {
		t.Fatalf("overlay definition = %+v", definition)
	}

	definition["name"] = "changed outside Lua"

	again, err := runtime.Definition("monsters", "MONS_TEST_MOSS")

	if err != nil {
		t.Fatal(err)
	}

	if again["name"] != "test moss" {
		t.Fatalf("definition was mutable through Go: %+v", again)
	}

	if _, err := runtime.Definition("monsters", "MONS_DOES_NOT_EXIST"); err == nil {
		t.Fatal("missing monster was accepted")
	}
}
