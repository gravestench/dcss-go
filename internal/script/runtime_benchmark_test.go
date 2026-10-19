package script

import (
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

func BenchmarkCatalogStartup(b *testing.B) {
	rules, err := modfs.Load()

	if err != nil {
		b.Fatal(err)
	}

	b.ResetTimer()

	for range b.N {
		world := akara.NewWorld()
		runtime, err := NewCatalog(world, rules)

		if err != nil {
			b.Fatal(err)
		}

		runtime.Close()
		world.Close()
	}
}
