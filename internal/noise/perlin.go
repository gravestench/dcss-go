package noise

import "math"

// The pinned DCSS perlin.cc is a public-domain C++ port of Stefan
// Gustavson's simplex noise. Only its 3D sampler and fBM are needed by
// the Abyss river distortion. The terrain choices remain in Lua.
var simplexPermutation = [256]uint8{
	151,
	160,
	137,
	91,
	90,
	15,
	131,
	13,
	201,
	95,
	96,
	53,
	194,
	233,
	7,
	225,
	140,
	36,
	103,
	30,
	69,
	142,
	8,
	99,
	37,
	240,
	21,
	10,
	23,
	190,
	6,
	148,
	247,
	120,
	234,
	75,
	0,
	26,
	197,
	62,
	94,
	252,
	219,
	203,
	117,
	35,
	11,
	32,
	57,
	177,
	33,
	88,
	237,
	149,
	56,
	87,
	174,
	20,
	125,
	136,
	171,
	168,
	68,
	175,
	74,
	165,
	71,
	134,
	139,
	48,
	27,
	166,
	77,
	146,
	158,
	231,
	83,
	111,
	229,
	122,
	60,
	211,
	133,
	230,
	220,
	105,
	92,
	41,
	55,
	46,
	245,
	40,
	244,
	102,
	143,
	54,
	65,
	25,
	63,
	161,
	1,
	216,
	80,
	73,
	209,
	76,
	132,
	187,
	208,
	89,
	18,
	169,
	200,
	196,
	135,
	130,
	116,
	188,
	159,
	86,
	164,
	100,
	109,
	198,
	173,
	186,
	3,
	64,
	52,
	217,
	226,
	250,
	124,
	123,
	5,
	202,
	38,
	147,
	118,
	126,
	255,
	82,
	85,
	212,
	207,
	206,
	59,
	227,
	47,
	16,
	58,
	17,
	182,
	189,
	28,
	42,
	223,
	183,
	170,
	213,
	119,
	248,
	152,
	2,
	44,
	154,
	163,
	70,
	221,
	153,
	101,
	155,
	167,
	43,
	172,
	9,
	129,
	22,
	39,
	253,
	19,
	98,
	108,
	110,
	79,
	113,
	224,
	232,
	178,
	185,
	112,
	104,
	218,
	246,
	97,
	228,
	251,
	34,
	242,
	193,
	238,
	210,
	144,
	12,
	191,
	179,
	162,
	241,
	81,
	51,
	145,
	235,
	249,
	14,
	239,
	107,
	49,
	192,
	214,
	31,
	181,
	199,
	106,
	157,
	184,
	84,
	204,
	176,
	115,
	121,
	50,
	45,
	127,
	4,
	150,
	254,
	138,
	236,
	205,
	93,
	222,
	114,
	67,
	29,
	24,
	72,
	243,
	141,
	128,
	195,
	78,
	66,
	215,
	61,
	156,
	180,
}

var simplexGradients = [12][3]float64{
	{
		1,
		1,
		0,
	},

	{
		-1,
		1,
		0,
	},

	{
		1,
		-1,
		0,
	},

	{
		-1,
		-1,
		0,
	},

	{
		1,
		0,
		1,
	},

	{
		-1,
		0,
		1,
	},

	{
		1,
		0,
		-1,
	},

	{
		-1,
		0,
		-1,
	},

	{
		0,
		1,
		1,
	},

	{
		0,
		-1,
		1,
	},

	{
		0,
		1,
		-1,
	},

	{
		0,
		-1,
		-1,
	},
}

func simplexPerm(index int64) int64 {
	return int64(simplexPermutation[uint8(index)])
}

// Simplex3 returns the source's 3D gradient value at exact float inputs.
// The corner ordering matters because each cell is one tetrahedron.
func Simplex3(x, y, z float64) float64 {
	skew := (x + y + z) / 3
	i := int64(math.Floor(x + skew))
	j := int64(math.Floor(y + skew))
	k := int64(math.Floor(z + skew))
	unskew := float64(i+j+k) / 6
	x0 := x - (float64(i) - unskew)
	y0 := y - (float64(j) - unskew)
	z0 := z - (float64(k) - unskew)
	first, second := simplexCorners(x0, y0, z0)

	offsets := [4][3]float64{
		{
			x0,
			y0,
			z0,
		},

		{
			x0 - float64(first[0]) + 1.0/6,
			y0 - float64(first[1]) + 1.0/6,
			z0 - float64(first[2]) + 1.0/6,
		},

		{
			x0 - float64(second[0]) + 2.0/6,
			y0 - float64(second[1]) + 2.0/6,
			z0 - float64(second[2]) + 2.0/6,
		},

		{
			x0 - 0.5,
			y0 - 0.5,
			z0 - 0.5,
		},
	}

	corners := [4][3]int64{
		{
			0,
			0,
			0,
		},

		first,
		second,
		{
			1,
			1,
			1,
		},
	}

	value := float64(0)

	for index, corner := range corners {
		gradient := simplexGradient(i+corner[0], j+corner[1], k+corner[2])
		distance := offsets[index]
		attenuation := 0.6 -
			distance[0]*distance[0] -
			distance[1]*distance[1] -
			distance[2]*distance[2]

		if attenuation <= 0 {
			continue
		}

		attenuation *= attenuation
		value += attenuation * attenuation * (gradient[0]*distance[0] +
			gradient[1]*distance[1] +
			gradient[2]*distance[2])
	}

	return 32 * value
}

// The source uses rank comparisons to choose its first two simplex corners.
func simplexCorners(x, y, z float64) ([3]int64, [3]int64) {
	if x >= y {
		if y >= z {
			return [3]int64{1, 0, 0}, [3]int64{1, 1, 0}
		}

		if x >= z {
			return [3]int64{1, 0, 0}, [3]int64{1, 0, 1}
		}

		return [3]int64{0, 0, 1}, [3]int64{1, 0, 1}
	}

	if y < z {
		return [3]int64{0, 0, 1}, [3]int64{0, 1, 1}
	}

	if x < z {
		return [3]int64{0, 1, 0}, [3]int64{0, 1, 1}
	}

	return [3]int64{0, 1, 0}, [3]int64{1, 1, 0}
}

func simplexGradient(i, j, k int64) [3]float64 {
	index := simplexPerm(i+simplexPerm(j+simplexPerm(k))) % 12

	return simplexGradients[index]
}

// FBM3 follows the source's five-octave river distortion path. The
// spatial rotation and z drift deliberately use its rounded constant.
func FBM3(x, y, z float64, octaves uint32) float64 {
	if octaves == 0 {
		return 0
	}

	if octaves == 1 {
		return Simplex3(x, y, z)
	}

	divisor := float64(1)
	norm := float64(0)
	value := float64(0)
	sine := math.Sin(1.41421356)
	cosine := math.Cos(1.41421356)

	for octave := uint32(0); octave < octaves; octave++ {
		value += Simplex3(x/divisor, y/divisor, z/divisor) / divisor
		// In the source divisor is uint32, so 1/divisor truncates to zero
		// after the first octave. Retain this visible source quirk.
		if octave == 0 {
			norm++
		}

		divisor *= 2
		nextX := y*sine + cosine
		y = y*cosine + sine
		x = nextX
		z += 1.7
	}

	return value / norm
}
