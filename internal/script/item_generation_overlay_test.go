package script

import (
	"testing"

	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

func TestItemGenerationOverlayDiscoversSubtypeAndPolicy(t *testing.T) {
	rules, err := modfs.Load("testdata/item-generation-overlay")

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

	result, err := runtime.Policy("test.item_generation_overlay", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["kind"] != "test sprocket" ||
		result["eligible"] != true ||
		result["weight"] != int64(7) ||
		result["plus"] != int64(4) {
		t.Fatalf("item-generation overlay = %+v", result)
	}
}
