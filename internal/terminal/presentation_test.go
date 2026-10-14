package terminal

import (
	"testing"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/script"
	"github.com/gravestench/akara"
)

func testPresentationPolicy(t *testing.T) presentationPolicy {
	t.Helper()
	rules, err := modfs.Load("")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	runtime, err := script.NewCatalog(world, rules)

	if err != nil {
		world.Close()

		t.Fatal(err)
	}

	t.Cleanup(func() {
		runtime.Close()
		world.Close()
	})

	return runtime.Policy
}
