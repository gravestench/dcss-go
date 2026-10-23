// Package noise provides reusable coordinate math for procedural Lua rules.
// Source layouts decide which samples become terrain; this package only
// preserves integer arithmetic that Lua numbers cannot represent exactly.
package noise

const (
	fnvOffset64 = uint64(0xcbf29ce484222325)
	fnvPrime64  = uint64(1099511628211)
	murmurMix32 = uint32(0x5bd1e995)
)

// Hash3 matches the pinned DCSS coordinate hash. The 64-bit products wrap,
// including when a negative world coordinate is converted to unsigned.
func Hash3(x, y int64, z uint64) uint64 {
	hash := fnvOffset64

	for _, value := range []uint64{
		uint64(x),
		uint64(y),
		z,
	} {
		hash ^= value
		hash *= fnvPrime64
	}

	return hash ^ (hash >> 27) ^ (hash << 24) ^ (hash >> 48)
}

// HashWithSeed gives a stable index into an ordered catalog. It reproduces
// source MurmurHash2 over two little-endian 32-bit words without allocating
// a byte buffer; this is the source borrowed-floor choice for the Abyss.
func HashWithSeed(count, seed, id uint32) uint32 {
	if count < 2 {
		return 0
	}

	hash := uint32(8)

	for _, word := range []uint32{
		seed,
		id,
	} {
		mixed := word * murmurMix32

		mixed ^= mixed >> 24
		mixed *= murmurMix32
		hash *= murmurMix32
		hash ^= mixed
	}

	hash ^= hash >> 13
	hash *= murmurMix32
	hash ^= hash >> 15

	return hash % count
}
