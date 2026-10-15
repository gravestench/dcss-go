package script

import (
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestOverlayAddsMutationEffectWithoutCentralRegistryEdit(t *testing.T) {
	rules, err := modfs.Load("testdata/add-mutation-effect")

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

	result, err := runtime.Policy("test.mutation_effect", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["flat_hp"] != int64(5) {
		t.Fatalf("modded mutation HP contribution = %v", result["flat_hp"])
	}

	if result["spell_failure"] != int64(1) {
		t.Fatalf("modded mutation spell contribution = %v", result["spell_failure"])
	}
}
