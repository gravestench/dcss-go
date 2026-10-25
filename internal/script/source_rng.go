package script

import "math/bits"

const sourcePCGMultiplier uint64 = 6364136223846793005

// sourceSubgenerator is a short-lived PCG stream for a deterministic local
// decision. It never alters the game's saved named RNG streams. The caller
// saves the completed result or its seed, so this cursor needs no save data.
type sourceSubgenerator struct {
	state uint64
	inc   uint64
	count uint64
}

// The pinned source initializes a PCG stream from game seed and sequence.
// It draws twice while seeding, then starts counting gameplay words at zero.
func newSourceSubgenerator(seed, sequence uint64) *sourceSubgenerator {
	rng := &sourceSubgenerator{
		inc: sequence<<1 | 1,
	}

	rng.next()
	rng.state += seed
	rng.next()
	rng.count = 0

	return rng
}

// Advance the source's XSH-RR PCG permutation using unsigned overflow.
func (r *sourceSubgenerator) next() uint32 {
	old := r.state
	nextState := old*sourcePCGMultiplier + r.inc

	r.state = nextState
	r.count++

	xorshifted := uint32(((old >> 18) ^ old) >> 27)
	rotation := int(old >> 59)

	return bits.RotateLeft32(xorshifted, -rotation)
}

// Source bounded draws use Lemire's multiply-high method. Rejected low
// products consume another word; bound one consumes none at all.
func (r *sourceSubgenerator) intn(bound uint32) uint32 {
	if bound <= 1 {
		return 0
	}

	threshold := -bound % bound

	for {
		product := uint64(r.next()) * uint64(bound)

		if uint32(product) >= threshold {
			return uint32(product >> 32)
		}
	}
}
