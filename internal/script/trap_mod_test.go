package script

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

func TestModTrapDiscoveryAndRulesetHash(t *testing.T) {
	base, err := modfs.Load("testdata/lua")

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/lua", "testdata/trap-mod")

	if err != nil {
		t.Fatal(err)
	}

	if base.Hash() == modded.Hash() || modded.Vanilla() {
		t.Fatal("trap overlay did not change effective ruleset hash")
	}

	runLuaRule(t, modded, "tests/trap_mod_test.lua")
}

func TestModTrapMissingEffectFailsAtLoad(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/trap-missing-effect")

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
		t.Fatal("missing trap effect was accepted")
	}

	if !strings.Contains(err.Error(),
		"missing trap effect policy/traps/effects/not_present.lua") {
		t.Fatalf("missing effect should name its path: %v", err)
	}
}
