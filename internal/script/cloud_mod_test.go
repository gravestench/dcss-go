package script

import (
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestCloudOverlayAddsAndOverridesDefinitions(t *testing.T) {
	base, err := modfs.Load("testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/lua", "testdata/cloud-mod")

	if err != nil {
		t.Fatal(err)
	}

	if base.Hash() == modded.Hash() || modded.Vanilla() {
		t.Fatal("cloud overlay must change effective ruleset identity")
	}

	runLuaRule(t, modded, "tests/cloud_mod_test.lua")
}

func TestCloudOverlayMissingEffectNamesRelativePath(t *testing.T) {
	rules, err := modfs.Load(
		"testdata/lua",
		"testdata/cloud-missing-effect",
	)

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
		t.Fatal("cloud with missing effect was accepted")
	}

	if !strings.Contains(err.Error(),
		"missing cloud effect policy/clouds/effects/not_present.lua") {
		t.Fatalf("missing cloud effect must name its path: %v", err)
	}
}
