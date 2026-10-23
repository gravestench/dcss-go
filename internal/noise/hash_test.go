package noise

import "testing"

// These vectors were calculated from the pinned DCSS hash functions. The
// generic procedural-noise kernel must keep their unsigned wrap behavior
// before Lua composes any source Abyss layout from them.
func TestSourceCoordinateHashes(t *testing.T) {
	for _, test := range []struct {
		name string
		x    int64
		y    int64
		z    uint64
		want uint64
	}{
		{
			name: "origin",
			x:    0,
			y:    0,
			z:    0,
			want: 13916436402438780407,
		},

		{
			name: "positive",
			x:    1,
			y:    2,
			z:    3,
			want: 14469308004222133773,
		},

		{
			name: "negative coordinate",
			x:    -1,
			y:    5,
			z:    10,
			want: 18046006020222318639,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			if got := Hash3(test.x, test.y, test.z); got != test.want {
				t.Fatalf("Hash3(%d, %d, %d) = %d, want %d",
					test.x, test.y, test.z, got, test.want)
			}
		})
	}
}

// The borrowed level uses the source's seeded MurmurHash2 index, including
// its zero result for a catalog with fewer than two eligible floors.
func TestSourceSeededIndex(t *testing.T) {
	for _, test := range []struct {
		count uint32
		seed  uint32
		want  uint32
	}{
		{
			count: 3,
			seed:  123,
			want:  0,
		},

		{
			count: 100,
			seed:  42,
			want:  11,
		},

		{
			count: 1,
			seed:  123,
			want:  0,
		},
	} {
		if got := HashWithSeed(test.count, test.seed, 0); got != test.want {
			t.Fatalf("HashWithSeed(%d, %d, 0) = %d, want %d",
				test.count, test.seed, got, test.want)
		}
	}
}
