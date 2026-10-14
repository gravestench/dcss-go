package content

const sourceRevision = "e60ba3568b0c26447ad36ec5c7b963eb04b2778f"

// scenarioCatalog contains only the non-species scenario rules.
// Human ID: species-data.h:483; Fighter ID: job-data.h:191.
// Potion kinds come from the committed starting-gear artifact.
// Player damage is a controlled scenario value, not DCSS combat parity.
func scenarioCatalog() Catalog {
	return Catalog{
		version:        1,
		sourceRevision: sourceRevision,
		player:         PlayerDef{SpeciesID: "SP_HUMAN", JobID: "JOB_FIGHTER", Speed: 10, BaseDamage: 4},
	}
}
