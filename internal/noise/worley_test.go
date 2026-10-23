package noise

import (
	"math"
	"testing"
)

// Vectors come from compiling the pinned standalone DCSS Worley source.
// This checks its IDs as well as distances, since Lua uses both to choose
// terrain families and the next morph point.
func TestWorleySourceVectors(t *testing.T) {
	tests := []struct {
		point float64
		ids   [2]uint32
		dist  [2]float64
	}{
		{
			point: 0,
			ids:   [2]uint32{779667506, 2226598506},
			dist:  [2]float64{0.648015886234, 1.183493989543},
		},

		{
			point: 1,
			ids:   [2]uint32{452604553, 586950981},
			dist:  [2]float64{1.263572521342, 1.348455347858},
		},

		{
			point: 41.5,
			ids:   [2]uint32{3687827106, 421711014},
			dist:  [2]float64{0.535775307667, 1.227446409135},
		},

		{
			point: 8192,
			ids:   [2]uint32{2726587023, 1131372968},
			dist:  [2]float64{1.110870968662, 1.283984317870},
		},
	}

	for _, test := range tests {
		got := Worley(test.point, test.point/2, test.point/3)

		if got.ID != test.ids {
			t.Errorf("Worley(%v) IDs = %v, want %v", test.point, got.ID, test.ids)
		}

		for index, want := range test.dist {
			if math.Abs(got.Distance[index]-want) > 1e-12 {
				t.Errorf("Worley(%v) distance %d = %.12f, want %.12f",
					test.point, index, got.Distance[index], want)
			}
		}
	}
}
