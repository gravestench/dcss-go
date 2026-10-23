// Package terrain defines the engine properties of dungeon feature IDs.
// Spell and generation policy select features; the grid uses these properties
// for occupancy, sight, and presentation.
package terrain

type ID string

const (
	Unseen             ID = ""
	Floor              ID = "DNGN_FLOOR"
	BlueFountain       ID = "DNGN_FOUNTAIN_BLUE"
	MagicFountain      ID = "DNGN_FOUNTAIN_MAGIC"
	DryFountain        ID = "DNGN_FOUNTAIN_DRY"
	BloodFountain      ID = "DNGN_FOUNTAIN_BLOOD"
	Altar              ID = "DNGN_RANDOM_ALTAR"
	ShopEntrance       ID = "DNGN_ENTER_SHOP"
	RockWall           ID = "DNGN_ROCK_WALL"
	StoneWall          ID = "DNGN_STONE_WALL"
	StoneArch          ID = "DNGN_STONE_ARCH"
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
	ClosedClearDoor    ID = "DNGN_CLOSED_CLEAR_DOOR"
	OpenClearDoor      ID = "DNGN_OPEN_CLEAR_DOOR"
	SealedDoor         ID = "DNGN_SEALED_DOOR"
	SealedClearDoor    ID = "DNGN_SEALED_CLEAR_DOOR"
	StairsUp           ID = "DNGN_STONE_STAIRS_UP_I"
	StairsDown         ID = "DNGN_STONE_STAIRS_DOWN_I"
	EnterBazaar        ID = "DNGN_ENTER_BAZAAR"
	ExitBazaar         ID = "DNGN_EXIT_BAZAAR"
	EnterSewer         ID = "DNGN_ENTER_SEWER"
	ExitSewer          ID = "DNGN_EXIT_SEWER"
	EnterOssuary       ID = "DNGN_ENTER_OSSUARY"
	ExitOssuary        ID = "DNGN_EXIT_OSSUARY"
	EnterBailey        ID = "DNGN_ENTER_BAILEY"
	ExitBailey         ID = "DNGN_EXIT_BAILEY"
	EnterIceCave       ID = "DNGN_ENTER_ICE_CAVE"
	ExitIceCave        ID = "DNGN_EXIT_ICE_CAVE"
	ExpiredPortal      ID = "DNGN_EXPIRED_PORTAL"
	EnterPandemonium   ID = "DNGN_ENTER_PANDEMONIUM"
	TransitPandemonium ID = "DNGN_TRANSIT_PANDEMONIUM"
	ExitPandemonium    ID = "DNGN_EXIT_PANDEMONIUM"
	ExitThroughAbyss   ID = "DNGN_EXIT_THROUGH_ABYSS"
	EnterHell          ID = "DNGN_ENTER_HELL"
	ExitHell           ID = "DNGN_EXIT_HELL"
	EnterDis           ID = "DNGN_ENTER_DIS"
	ExitDis            ID = "DNGN_EXIT_DIS"
	EnterGehenna       ID = "DNGN_ENTER_GEHENNA"
	ExitGehenna        ID = "DNGN_EXIT_GEHENNA"
	EnterCocytus       ID = "DNGN_ENTER_COCYTUS"
	ExitCocytus        ID = "DNGN_EXIT_COCYTUS"
	EnterTartarus      ID = "DNGN_ENTER_TARTARUS"
	ExitTartarus       ID = "DNGN_EXIT_TARTARUS"
	SealedStairsUp     ID = "DNGN_SEALED_STAIRS_UP"
	SealedStairsDown   ID = "DNGN_SEALED_STAIRS_DOWN"
	MalignGateway      ID = "DNGN_MALIGN_GATEWAY"
	PassageOfGolubria  ID = "DNGN_PASSAGE_OF_GOLUBRIA"
	Transporter        ID = "DNGN_TRANSPORTER"
	TransporterLanding ID = "DNGN_TRANSPORTER_LANDING"
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

	BlueFountain: {
		Glyph:    '⌠',
		Walkable: true,
	},

	MagicFountain: {
		Glyph:    '⌠',
		Walkable: true,
	},

	DryFountain: {
		Glyph:    '⌠',
		Walkable: true,
	},

	BloodFountain: {
		Glyph:    '⌠',
		Walkable: true,
	},

	Altar: {
		Glyph:    '_',
		Walkable: true,
	},

	ShopEntrance: {
		Glyph:    '∩',
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

	StoneArch: {
		Glyph:    '∩',
		Walkable: true,
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

	ClosedClearDoor: {Glyph: '+'},

	OpenClearDoor: {
		Glyph:    '\'',
		Walkable: true,
	},

	SealedDoor: {
		Glyph:  '+',
		Opaque: true,
	},
	SealedClearDoor: {Glyph: '+'},

	StairsUp: {
		Glyph:    '<',
		Walkable: true,
	},

	StairsDown: {
		Glyph:    '>',
		Walkable: true,
	},

	// A Bazaar entrance is temporary or permanent according to saved Lua
	// policy. Both gate directions remain distinct live terrain identities.
	EnterBazaar: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitBazaar: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterSewer: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitSewer: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterOssuary: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitOssuary: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterBailey: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitBailey: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterIceCave: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitIceCave: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExpiredPortal: {
		Glyph:    '∩',
		Walkable: true,
	},

	// DCSS draws these portals as arches. Their IDs remain distinct so
	// Lua policy can route each gate without inspecting a vault record.
	EnterPandemonium: {
		Glyph:    '∩',
		Walkable: true,
	},

	TransitPandemonium: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitPandemonium: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitThroughAbyss: {
		Glyph:    '∩',
		Walkable: true,
	},

	// The Vestibule and each of its four branches use source portal arches.
	// Distinct IDs preserve the branch destination through save and restore.
	EnterHell: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitHell: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterDis: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitDis: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterGehenna: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitGehenna: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterCocytus: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitCocytus: {
		Glyph:    '∩',
		Walkable: true,
	},

	EnterTartarus: {
		Glyph:    '∩',
		Walkable: true,
	},

	ExitTartarus: {
		Glyph:    '∩',
		Walkable: true,
	},

	SealedStairsUp: {
		Glyph:    '<',
		Walkable: true,
	},

	SealedStairsDown: {
		Glyph:    '>',
		Walkable: true,
	},

	MalignGateway: {Glyph: 'w'},
	PassageOfGolubria: {
		Glyph:    '^',
		Walkable: true,
	},

	Transporter: {
		Glyph:    '©',
		Walkable: true,
	},

	TransporterLanding: {
		Glyph:    '©',
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

// Sealed stairs retain their travel link while suppressing ordinary stair use.
func IsLinkedStair(id ID) bool {
	return IsStair(id) ||
		id == SealedStairsUp ||
		id == SealedStairsDown
}
