package content

const sourceRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

// scenarioCatalog contains only the non-species content required by the fixed Dungeon slice.
// Rat glyph, speed, and bite damage: crawl-ref/source/mon-data.h:1994-2001.
// Human ID: species-data.h:483; Fighter ID: job-data.h:191.
// Potion kinds come from the committed starting-gear artifact.
// Player damage is a controlled scenario value, not DCSS combat parity.
func scenarioCatalog() Catalog {
	return Catalog{
		version:        1,
		sourceRevision: sourceRevision,
		monsters: map[string]MonsterDef{
			"MONS_RAT": {ID: "MONS_RAT", Status: MonsterDefined, SourcePath: "crawl-ref/source/mon-data.h", SourceLine: 1994,
				Name: "rat", Glyph: 'r', ColourID: "BROWN", Flags: []string{"M_WARM_BLOOD"}, XPModifier: 1,
				GenusID: "MONS_RAT", SpeciesID: "MONS_RAT", Holiness: []string{"MH_NATURAL"},
				Attacks: [4]MonsterAttack{{TypeID: "AT_BITE", FlavourID: "AF_PLAIN", Damage: 3},
					{TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}, {TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}, {TypeID: "AT_NONE", FlavourID: "AF_PLAIN"}},
				HD: 1, AverageHP10x: 25, AC: 1, EV: 10, SpellbookID: "MST_NO_SPELLS", LeavesCorpse: true,
				ShoutID: "S_SILENT", IntelligenceID: "I_ANIMAL", HabitatID: "HT_LAND", Speed: 10,
				Energy:    MonsterEnergy{Move: 10, Swim: 10, Attack: 10, Missile: 10, Spell: 10, Special: 10, Item: 10, PickupPercent: 100},
				ItemUseID: "MONUSE_NOTHING", SizeID: "SIZE_TINY", ShapeID: "MON_SHAPE_QUADRUPED",
				Tile: MonsterTile{ID: "TILEP_MONS_RAT", VariationID: "TVARY_NONE"}, CorpseTileID: "TILE_CORPSE_RAT"},
		},
		player: PlayerDef{SpeciesID: "SP_HUMAN", JobID: "JOB_FIGHTER", Speed: 10, BaseDamage: 4},
	}
}
