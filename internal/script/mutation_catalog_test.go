package script

import (
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestInvalidMutationOverlayFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/invalid-mutation")

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
		t.Fatal("invalid mutation definition was accepted")
	}

	for _, wanted := range []string{
		"content/mutations/zz_bad.lua",
		"max_level",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("mutation error omitted %q: %v", wanted, err)
		}
	}
}

func TestMutationWithoutBehaviorFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/missing-mutation-effect")

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
		t.Fatal("active mutation without behavior was accepted")
	}

	for _, wanted := range []string{
		"content/mutations/zz_missing.lua",
		"MUT_MISSING_EFFECT",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("mutation error omitted %q: %v", wanted, err)
		}
	}
}
