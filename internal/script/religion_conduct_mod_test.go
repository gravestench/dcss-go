package script

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

// A new god may own a sparse conduct module. Validation reports the
// winning definition path when that module is absent.
func TestReligionConductMissingModuleFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/lua",
		"testdata/religion-conduct-missing")

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
		t.Fatal("missing conduct module was accepted")
	}

	if !strings.Contains(err.Error(),
		"content/gods/test_conduct.lua") ||
		!strings.Contains(err.Error(), "missing conduct module") {
		t.Fatalf("missing module error omitted winning origin: %v", err)
	}
}

// A replacement Lua rule with a misspelled event must fail while the
// effective mod is loaded, before a player reaches that god's altar.
func TestReligionConductUnknownEventFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/lua",
		"testdata/religion-conduct-unknown-event")

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
		t.Fatal("unknown conduct event was accepted")
	}

	if !strings.Contains(err.Error(),
		"unknown conduct event misspelled_event") {
		t.Fatalf("unknown conduct event was accepted: %v", err)
	}
}

// A mod cannot invert a god's offense by supplying a negative factor.
// The resolved rule path belongs in the diagnostic so the author can fix it.
func TestReligionConductInvalidFactorFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/lua",
		"testdata/religion-conduct-invalid-factor")

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
		t.Fatal("invalid conduct factor was accepted")
	}

	if !strings.Contains(err.Error(),
		"policy/religion/conduct/zin.lua") ||
		!strings.Contains(err.Error(), "nonnegative loss_factor") {
		t.Fatalf("invalid conduct factor was accepted: %v", err)
	}
}
