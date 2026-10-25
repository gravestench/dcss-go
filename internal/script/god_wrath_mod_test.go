package script

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

// The loader reports a missing god wrath method against its winning Lua
// definition before a player can reach the modded altar.
func TestGodWrathMissingModuleFailsAtBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/lua", "testdata/god-wrath-missing")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if runtime != nil {
		runtime.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/gods/test_missing.lua") ||
		!strings.Contains(err.Error(), "missing wrath module") {
		t.Fatalf("missing wrath module lacked its origin: %v", err)
	}
}
