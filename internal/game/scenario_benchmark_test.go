package game

import "testing"

func BenchmarkNewScenario(b *testing.B) {
	for range b.N {
		g, err := NewScenario(1, "WPN_RAPIER", "Benchmark")

		if err != nil {
			b.Fatal(err)
		}

		g.Close()
	}
}
