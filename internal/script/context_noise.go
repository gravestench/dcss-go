package script

import (
	"math"

	"crawl/internal/noise"

	lua "github.com/yuin/gopher-lua"
)

// Noise bridge methods expose generic exact math. Lua decides what a
// sample means for terrain; Go only keeps the source's integer wrap and
// cellular arithmetic beyond Lua's exact floating-point integer range.

func noiseInteger(
	state *lua.LState,
	position int,
	minimum, maximum float64,
) int64 {
	number, err := exactLuaNumber(state.Get(position))

	if err != nil ||
		number < minimum ||
		number > maximum {
		state.RaiseError("noise argument %d must be an exact integer in range", position-1)

		return 0
	}

	return int64(number)
}

// hash3_quotient_mod computes (hash3(x, y, z) / quotient) % modulus.
// Lua cannot exactly represent a 64-bit hash, but every source consumer
// only needs a small remainder of it or of one of its quotients.
func (r *Runtime) luaHash3QuotientMod(state *lua.LState) int {
	x := noiseInteger(state, 2, -2147483648, 2147483647)
	y := noiseInteger(state, 3, -2147483648, 2147483647)
	z := uint64(noiseInteger(state, 4, 0, 9007199254740991))
	quotient := uint64(noiseInteger(state, 5, 1, 9007199254740991))
	modulus := uint64(noiseInteger(state, 6, 1, 9007199254740991))
	result := (noise.Hash3(x, y, z) / quotient) % modulus

	state.Push(lua.LNumber(result))

	return 1
}

// worley returns source point IDs and distances as named Lua arrays.
// Keeping the table shape here prevents procedural policies from ever
// depending on an opaque userdata or Go struct layout.
func (r *Runtime) luaWorley(state *lua.LState) int {
	coordinates := [3]float64{}

	for index := range coordinates {
		value, ok := state.Get(index + 2).(lua.LNumber)

		if !ok ||
			math.IsNaN(float64(value)) ||
			math.IsInf(float64(value), 0) ||
			math.Abs(float64(value)) > 2147483647 {
			state.RaiseError("worley argument %d must be a finite coordinate", index+1)

			return 0
		}

		coordinates[index] = float64(value)
	}

	sample := noise.Worley(coordinates[0], coordinates[1], coordinates[2])
	result := state.NewTable()
	distances := state.NewTable()
	ids := state.NewTable()

	for index := range sample.Distance {
		distances.Append(lua.LNumber(sample.Distance[index]))
		ids.Append(lua.LNumber(sample.ID[index]))
	}

	state.SetField(result, "distance", distances)
	state.SetField(result, "id", ids)
	state.Push(result)

	return 1
}

// fbm3 is a reusable numeric primitive for Lua spatial policy. The
// source river layout asks for five octaves; the caller chooses inputs.
func (r *Runtime) luaFBM3(state *lua.LState) int {
	coordinates := [3]float64{}

	for index := range coordinates {
		value, ok := state.Get(index + 2).(lua.LNumber)

		if !ok ||
			math.IsNaN(float64(value)) ||
			math.IsInf(float64(value), 0) ||
			math.Abs(float64(value)) > 2147483647 {
			state.RaiseError("fbm3 argument %d must be a finite coordinate", index+1)

			return 0
		}

		coordinates[index] = float64(value)
	}

	octaves := noiseInteger(state, 5, 1, 16)
	result := noise.FBM3(coordinates[0], coordinates[1],
		coordinates[2], uint32(octaves))
	state.Push(lua.LNumber(result))

	return 1
}

// xor_u32 keeps source point-ID parity exact without introducing a
// branch-specific rule into Go.
func (r *Runtime) luaXorU32(state *lua.LState) int {
	left := uint32(noiseInteger(state, 2, 0, 4294967295))
	right := uint32(noiseInteger(state, 3, 0, 4294967295))
	seed := uint32(noiseInteger(state, 4, 0, 4294967295))
	state.Push(lua.LNumber(left ^ right ^ seed))

	return 1
}
