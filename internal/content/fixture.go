package content

const sourceRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

// scenarioCatalog contains only the non-species content required by the fixed Dungeon slice.
// Rat glyph, speed, and bite damage: crawl-ref/source/mon-data.h:1994-2001.
// Human ID: species-data.h:483; Fighter ID: job-data.h:191.
// Potion ID: potion-type.h:11; name: item-name.cc:671.
// HP and player damage are controlled scenario values, not DCSS generation parity.
func scenarioCatalog() Catalog {
	return Catalog{
		version:        1,
		sourceRevision: sourceRevision,
		monsters: map[string]MonsterDef{
			"MONS_RAT": {ID: "MONS_RAT", Name: "rat", Glyph: 'r', Speed: 10, BaseDamage: 3, ScenarioHP: 4},
		},
		items: map[string]ItemDef{
			"POT_CURING": {ID: "POT_CURING", Name: "potion of curing", Glyph: '!'},
		},
		player: PlayerDef{SpeciesID: "SP_HUMAN", JobID: "JOB_FIGHTER", ScenarioHP: 20, Speed: 10, BaseDamage: 4},
	}
}
