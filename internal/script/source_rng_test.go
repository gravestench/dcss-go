package script

import "testing"

// The source's private PCG stream has fixed output for a seed and sequence.
// These vectors are from the pinned PCG implementation, independent of the
// main game's named SplitMix streams.
func TestSourceSubgeneratorMatchesPCGVectors(t *testing.T) {
	rng := newSourceSubgenerator(42, 54)
	want := []uint32{
		0xa15c02b7,
		0x7b47f409,
		0xba1d3330,
		0x83d2f293,
		0xbfa4784b,
		0xcbed606e,
	}

	for index, expected := range want {
		if got := rng.next(); got != expected {
			t.Fatalf("word %d = %#x, want %#x", index, got, expected)
		}
	}
}

// Source random2(1) returns zero without advancing the private stream.
// A later name draw must match the same seeded word sequence.
func TestSourceSubgeneratorBoundedDraws(t *testing.T) {
	rng := newSourceSubgenerator(42, 54)
	checks := []struct {
		bound uint32
		want  uint32
	}{
		{
			bound: 1,
			want:  0,
		},

		{
			bound: 5,
			want:  3,
		},

		{
			bound: 151,
			want:  72,
		},

		{
			bound: 7,
			want:  5,
		},

		{
			bound: 151,
			want:  77,
		},

		{
			bound: 5,
			want:  3,
		},
	}

	for index, check := range checks {
		if got := rng.intn(check.bound); got != check.want {
			t.Fatalf("draw %d at bound %d = %d, want %d",
				index, check.bound, got, check.want)
		}
	}

	if rng.count != 5 {
		t.Fatalf("private stream consumed %d words, want 5", rng.count)
	}
}

// Two local streams built with the same seed do not share a mutable cursor.
func TestSourceSubgeneratorIndependentInstances(t *testing.T) {
	first := newSourceSubgenerator(42, 54)
	second := newSourceSubgenerator(42, 54)

	first.next()

	if got := second.next(); got != 0xa15c02b7 {
		t.Fatalf("second stream first word = %#x", got)
	}
}

// A bound just above half the word range rejects the first seeded word.
// Comparing the returned value and count checks Lemire's low-product path.
func TestSourceSubgeneratorRejectsBiasedLowProduct(t *testing.T) {
	rng := newSourceSubgenerator(42, 54)

	if got := rng.intn(0x80000001); got != 0x3da3fa04 {
		t.Fatalf("rejected bounded draw = %#x", got)
	}

	if rng.count != 2 {
		t.Fatalf("rejection consumed %d words, want 2", rng.count)
	}
}
