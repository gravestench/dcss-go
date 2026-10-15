// Package terrain defines the engine properties of dungeon feature IDs.
// Spell and generation policy select features; the grid uses these properties
// for occupancy, sight, and presentation.
package terrain

type ID string

const (
	Unseen             ID = ""
	Floor              ID = "DNGN_FLOOR"
	RockWall           ID = "DNGN_ROCK_WALL"
	StoneWall          ID = "DNGN_STONE_WALL"
	MetalWall          ID = "DNGN_METAL_WALL"
	CrystalWall        ID = "DNGN_CRYSTAL_WALL"
	PermaRockWall      ID = "DNGN_PERMAROCK_WALL"
	ClearRockWall      ID = "DNGN_CLEAR_ROCK_WALL"
	ClearStoneWall     ID = "DNGN_CLEAR_STONE_WALL"
	ClearPermaRockWall ID = "DNGN_CLEAR_PERMAROCK_WALL"
	SlimyWall          ID = "DNGN_SLIMY_WALL"
	Grate              ID = "DNGN_GRATE"
	OrcishIdol         ID = "DNGN_ORCISH_IDOL"
	GraniteStatue      ID = "DNGN_GRANITE_STATUE"
	PetrifiedTree      ID = "DNGN_PETRIFIED_TREE"
	Tree               ID = "DNGN_TREE"
	Mangrove           ID = "DNGN_MANGROVE"
	DemonicTree        ID = "DNGN_DEMONIC_TREE"
	OpenSea            ID = "DNGN_OPEN_SEA"
	LavaSea            ID = "DNGN_LAVA_SEA"
	ShallowWater       ID = "DNGN_SHALLOW_WATER"
	ToxicBog           ID = "DNGN_TOXIC_BOG"
	DeepWater          ID = "DNGN_DEEP_WATER"
	Lava               ID = "DNGN_LAVA"
	ClosedDoor         ID = "DNGN_CLOSED_DOOR"
	OpenDoor           ID = "DNGN_OPEN_DOOR"
	StairsUp           ID = "DNGN_STONE_STAIRS_UP_I"
	StairsDown         ID = "DNGN_STONE_STAIRS_DOWN_I"
	MalignGateway      ID = "DNGN_MALIGN_GATEWAY"
	PassageOfGolubria  ID = "DNGN_PASSAGE_OF_GOLUBRIA"
)

type Feature struct {
	Glyph    rune
	Walkable bool
	Opaque   bool
	Watery   bool
	Diggable bool
}

var definitions = map[ID]Feature{
	Floor: {
		Glyph:    '.',
		Walkable: true,
	},

	RockWall: {
		Glyph:    '#',
		Opaque:   true,
		Diggable: true,
	},

	StoneWall: {
		Glyph:  '#',
		Opaque: true,
	},

	MetalWall: {
		Glyph:  '#',
		Opaque: true,
	},

	CrystalWall: {
		Glyph:  '#',
		Opaque: true,
	},

	PermaRockWall: {
		Glyph:  '#',
		Opaque: true,
	},

	ClearRockWall: {
		Glyph:    '#',
		Diggable: true,
	},
	ClearStoneWall:     {Glyph: '#'},
	ClearPermaRockWall: {Glyph: '#'},
	SlimyWall: {
		Glyph:    '#',
		Opaque:   true,
		Diggable: true,
	},

	Grate: {
		Glyph:    '#',
		Diggable: true,
	},

	OrcishIdol: {
		Glyph:    '#',
		Diggable: true,
	},

	GraniteStatue: {
		Glyph:    '#',
		Diggable: true,
	},

	PetrifiedTree: {
		Glyph:    '#',
		Opaque:   true,
		Diggable: true,
	},

	Tree: {
		Glyph:  '#',
		Opaque: true,
	},

	Mangrove: {
		Glyph:  '#',
		Opaque: true,
	},

	DemonicTree: {
		Glyph:  '#',
		Opaque: true,
	},

	OpenSea: {
		Glyph:  '#',
		Watery: true,
	},
	LavaSea: {Glyph: '#'},
	ShallowWater: {
		Glyph:    '~',
		Walkable: true,
		Watery:   true,
	},

	ToxicBog: {
		Glyph:    '~',
		Walkable: true,
		Watery:   true,
	},

	DeepWater: {
		Glyph:    '~',
		Walkable: true,
		Watery:   true,
	},

	Lava: {
		Glyph:    '~',
		Walkable: true,
	},

	ClosedDoor: {
		Glyph:  '+',
		Opaque: true,
	},

	OpenDoor: {
		Glyph:    '\'',
		Walkable: true,
	},

	StairsUp: {
		Glyph:    '<',
		Walkable: true,
	},

	StairsDown: {
		Glyph:    '>',
		Walkable: true,
	},
	MalignGateway: {Glyph: 'w'},
	PassageOfGolubria: {
		Glyph:    '^',
		Walkable: true,
	},
}

func Lookup(id ID) (Feature, bool) {
	feature, found := definitions[id]

	return feature, found
}

func Valid(id ID) bool {
	_, found := Lookup(id)

	return found
}

func Walkable(id ID) bool {
	feature, found := Lookup(id)

	return found && feature.Walkable
}

func Opaque(id ID) bool {
	feature, found := Lookup(id)

	return !found || feature.Opaque
}

func Glyph(id ID) rune {
	feature, found := Lookup(id)

	if !found {
		return ' '
	}

	return feature.Glyph
}

func IsStair(id ID) bool {
	return id == StairsUp || id == StairsDown
}
