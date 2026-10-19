package script

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

func TestPotionWithoutEffectFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/missing-potion-effect")

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
		t.Fatal("active potion without behavior was accepted")
	}

	for _, wanted := range []string{
		"POT_MISSING_EFFECT",
		"content/items/zz_missing_potion.lua",
	} {
		if !strings.Contains(err.Error(), wanted) {
			t.Fatalf("missing potion error omitted %q: %v", wanted, err)
		}
	}
}

func TestPotionEffectOverlayReplacesOneFile(t *testing.T) {
	rules, err := modfs.Load("testdata/override-potion-effect")

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

	result, err := runtime.Policy("test.potion_effect", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["message"] != "The overlaid curing effect ran." {
		t.Fatalf("modded potion result = %v", result["message"])
	}
}
