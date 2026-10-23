package noise

import "math"

// The cellular sampler follows Steven Worley's implementation used by the
// pinned DCSS source. Its license permits use and redistribution with this
// notice:
//
// Copyright 1994, 2002 by Steven Worley
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

const worleyDensity = 0.398150

const worleyScale = 1 / worleyDensity

const worleyLCG = uint32(1402024253)

const worleyIncrement = uint32(586950981)

// This source lookup approximates a Poisson distribution of feature points
// per cube. IDs and the morph texture change if its order changes.
var poissonCounts = [256]uint8{
	4,
	3,
	1,
	1,
	1,
	2,
	4,
	2,
	2,
	2,
	5,
	1,
	0,
	2,
	1,
	2,
	2,
	0,
	4,
	3,
	2,
	1,
	2,
	1,
	3,
	2,
	2,
	4,
	2,
	2,
	5,
	1,
	2,
	3,
	2,
	2,
	2,
	2,
	2,
	3,
	2,
	4,
	2,
	5,
	3,
	2,
	2,
	2,
	5,
	3,
	3,
	5,
	2,
	1,
	3,
	3,
	4,
	4,
	2,
	3,
	0,
	4,
	2,
	2,
	2,
	1,
	3,
	2,
	2,
	2,
	3,
	3,
	3,
	1,
	2,
	0,
	2,
	1,
	1,
	2,
	2,
	2,
	2,
	5,
	3,
	2,
	3,
	2,
	3,
	2,
	2,
	1,
	0,
	2,
	1,
	1,
	2,
	1,
	2,
	2,
	1,
	3,
	4,
	2,
	2,
	2,
	5,
	4,
	2,
	4,
	2,
	2,
	5,
	4,
	3,
	2,
	2,
	5,
	4,
	3,
	3,
	3,
	5,
	2,
	2,
	2,
	2,
	2,
	3,
	1,
	1,
	4,
	2,
	1,
	3,
	3,
	4,
	3,
	2,
	4,
	3,
	3,
	3,
	4,
	5,
	1,
	4,
	2,
	4,
	3,
	1,
	2,
	3,
	5,
	3,
	2,
	1,
	3,
	1,
	3,
	3,
	3,
	2,
	3,
	1,
	5,
	5,
	4,
	2,
	2,
	4,
	1,
	3,
	4,
	1,
	5,
	3,
	3,
	5,
	3,
	4,
	3,
	2,
	2,
	1,
	1,
	1,
	1,
	1,
	2,
	4,
	5,
	4,
	5,
	4,
	2,
	1,
	5,
	1,
	1,
	2,
	3,
	3,
	3,
	2,
	5,
	2,
	3,
	3,
	2,
	0,
	2,
	1,
	1,
	4,
	2,
	1,
	3,
	2,
	1,
	2,
	2,
	3,
	2,
	5,
	5,
	3,
	4,
	5,
	5,
	2,
	4,
	4,
	5,
	3,
	2,
	2,
	2,
	1,
	4,
	2,
	3,
	3,
	4,
	2,
	5,
	4,
	2,
	2,
	2,
	2,
	2,
	4,
	5,
	3,
	2,
}

// CellularSample carries the two closest feature points. DCSS uses the
// distance gap for changepoints and point IDs for region selection.
type CellularSample struct {
	Distance [2]float64
	ID       [2]uint32
}

type worleyCandidate struct {
	distanceSquared float64
	id              uint32
}

// Worley returns the first two cellular features at a 3D location.
// Evaluating the complete 3×3×3 neighborhood is simpler than the source's
// distance-pruned traversal and yields the same nearest features.
func Worley(x, y, z float64) CellularSample {
	point := [3]float64{
		x * worleyDensity,
		y * worleyDensity,
		z * worleyDensity,
	}

	origin := [3]int32{
		sourceFloor(point[0]),
		sourceFloor(point[1]),
		sourceFloor(point[2]),
	}

	best := [2]worleyCandidate{
		{distanceSquared: math.MaxFloat64},
		{distanceSquared: math.MaxFloat64},
	}

	// The centre is visited first, as in the source. The remaining cubes
	// cannot have a closer point beyond this one-cube neighborhood.
	visitCube(origin[0], origin[1], origin[2], point, &best)

	for dz := int32(-1); dz <= 1; dz++ {
		for dy := int32(-1); dy <= 1; dy++ {
			for dx := int32(-1); dx <= 1; dx++ {
				if dx == 0 &&
					dy == 0 &&
					dz == 0 {
					continue
				}

				visitCube(origin[0]+dx, origin[1]+dy, origin[2]+dz, point, &best)
			}
		}
	}

	return CellularSample{
		Distance: [2]float64{
			math.Sqrt(best[0].distanceSquared) * worleyScale,
			math.Sqrt(best[1].distanceSquared) * worleyScale,
		},
		ID: [2]uint32{
			best[0].id,
			best[1].id,
		},
	}
}

// Source LFLOOR subtracts one for negative integral values too. Preserve
// that boundary behavior so a mod sampling a negative world cell is stable.
func sourceFloor(value float64) int32 {
	if value < 0 {
		return int32(value) - 1
	}

	return int32(value)
}

// Cube seeds and the LCG deliberately wrap at 32 bits. Converting signed
// coordinates before multiplication reproduces the source's uint32 seed.
func visitCube(
	x, y, z int32,
	point [3]float64,
	best *[2]worleyCandidate,
) {
	seed := uint32(702395077)*uint32(x) +
		uint32(915488749)*uint32(y) +
		uint32(2120969693)*uint32(z)
	count := poissonCounts[seed>>24]
	seed = worleyLCG*seed + worleyIncrement

	for index := uint8(0); index < count; index++ {
		id := seed
		seed = worleyLCG*seed + worleyIncrement
		fx := (float64(seed) + 0.5) / 4294967296.0
		seed = worleyLCG*seed + worleyIncrement
		fy := (float64(seed) + 0.5) / 4294967296.0
		seed = worleyLCG*seed + worleyIncrement
		fz := (float64(seed) + 0.5) / 4294967296.0
		seed = worleyLCG*seed + worleyIncrement

		dx := float64(x) + fx - point[0]
		dy := float64(y) + fy - point[1]
		dz := float64(z) + fz - point[2]
		distance := dx*dx + dy*dy + dz*dz

		if distance < best[0].distanceSquared {
			best[1] = best[0]
			best[0] = worleyCandidate{
				distanceSquared: distance,
				id:              id,
			}
		} else if distance < best[1].distanceSquared {
			best[1] = worleyCandidate{
				distanceSquared: distance,
				id:              id,
			}
		}
	}
}
