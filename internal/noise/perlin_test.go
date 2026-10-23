package noise

import (
	"math"
	"testing"
)

// These are from the pinned DCSS standalone 3D simplex and fBM functions.
func TestSimplexSourceVectors(t *testing.T) {
	tests := []struct {
		point   float64
		simplex float64
		fbm     float64
	}{
		{
			point:   0,
			simplex: 0,
			fbm:     0.147090148663,
		},

		{
			point:   0.25,
			simplex: 0.895057991911,
			fbm:     1.000679266383,
		},

		{
			point:   1,
			simplex: -0.654706533557,
			fbm:     -0.695870397948,
		},

		{
			point:   41.5,
			simplex: -0.899718493662,
			fbm:     -0.743704235594,
		},
	}

	for _, test := range tests {
		x, y, z := test.point, test.point/2, test.point/3

		if got := Simplex3(x, y, z); math.Abs(got-test.simplex) > 1e-12 {
			t.Errorf("Simplex3(%v) = %.12f, want %.12f", test.point, got, test.simplex)
		}

		if got := FBM3(x, y, z, 5); math.Abs(got-test.fbm) > 1e-12 {
			t.Errorf("FBM3(%v) = %.12f, want %.12f", test.point, got, test.fbm)
		}
	}
}
