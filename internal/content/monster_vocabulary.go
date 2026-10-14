package content

import (
	"fmt"
	"slices"
	"strings"
)

// MonsterVocabulary is committed independently of the definition table.
// It lets normal startup verify source IDs and enums without a C++ checkout.
type MonsterVocabulary struct {
	SchemaVersion   int                 `json:"schema_version"`
	SourceRevision  string              `json:"source_revision"`
	TagMajorVersion int                 `json:"tag_major_version"`
	SourceFiles     []JobSourceFile     `json:"source_files"`
	Identities      []MonsterIdentity   `json:"identities"`
	Symbols         map[string][]string `json:"symbols"`
}

type MonsterIdentity struct {
	ID     string        `json:"id"`
	Status MonsterStatus `json:"status"`
}

func (v MonsterVocabulary) ValidateArtifact(a MonsterArtifact) error {
	if v.SchemaVersion != 1 || v.SourceRevision != a.SourceRevision ||
		v.TagMajorVersion != a.TagMajorVersion || len(v.Identities) != len(a.Monsters) ||
		len(v.SourceFiles) != len(a.SourceFiles) {
		return fmt.Errorf("monster vocabulary metadata or coverage differs")
	}

	for i, file := range v.SourceFiles {
		if file != a.SourceFiles[i] {
			return fmt.Errorf("monster vocabulary source hash differs for %s", file.Path)
		}
	}

	for i, identity := range v.Identities {
		if identity.ID != a.Monsters[i].ID || identity.Status != a.Monsters[i].Status {
			return fmt.Errorf("monster identity/status differs at %s", identity.ID)
		}
	}

	sets, err := v.validatedSymbolSets()

	if err != nil {
		return err
	}

	for _, monster := range a.Monsters {
		if monster.Status != MonsterDefined {
			continue
		}

		if err := validateMonsterVocabularyEntry(monster, sets); err != nil {
			return err
		}
	}

	return nil
}

func (v MonsterVocabulary) validatedSymbolSets() (map[string]map[string]bool, error) {
	needed := []string{
		"attack_type",
		"attack_flavour",
		"spellbook",
		"class_flag",
		"resistance",
		"holiness",
		"shout",
		"intelligence",
		"habitat",
		"item_use",
		"size",
		"shape",
		"colour",
		"tile_variation",
	}

	sets := make(map[string]map[string]bool, len(needed))

	for _, category := range needed {
		values := v.Symbols[category]

		if len(values) == 0 || !slices.IsSorted(values) {
			return nil, fmt.Errorf("missing or unsorted monster vocabulary %s", category)
		}

		set := make(map[string]bool, len(values))

		for _, value := range values {
			if value == "" || set[value] {
				return nil, fmt.Errorf("bad monster vocabulary %s: %s", category, value)
			}

			set[value] = true
		}

		sets[category] = set
	}

	return sets, nil
}

func validateMonsterVocabularyEntry(
	m MonsterDef,
	sets map[string]map[string]bool,
) error {
	check := func(category, value, monsterID string) error {
		if !sets[category][value] {
			return fmt.Errorf("monster %s has unknown %s %q", monsterID, category, value)
		}

		return nil
	}

	for _, pair := range []struct {
		category string
		value    string
	}{
		{
			category: "colour",
			value:    m.ColourID,
		},
		{
			category: "spellbook",
			value:    m.SpellbookID,
		},
		{
			category: "shout",
			value:    m.ShoutID,
		},
		{
			category: "intelligence",
			value:    m.IntelligenceID,
		},
		{
			category: "habitat",
			value:    m.HabitatID,
		},
		{
			category: "item_use",
			value:    m.ItemUseID,
		},
		{
			category: "size",
			value:    m.SizeID,
		},
		{
			category: "shape",
			value:    m.ShapeID,
		},
		{
			category: "tile_variation",
			value:    m.Tile.VariationID,
		},
	} {
		if err := check(pair.category, pair.value, m.ID); err != nil {
			return err
		}
	}

	for _, id := range m.Flags {
		if err := check("class_flag", id, m.ID); err != nil {
			return err
		}
	}

	for _, id := range m.Holiness {
		if err := check("holiness", id, m.ID); err != nil {
			return err
		}
	}

	for _, r := range m.Resistances {
		if err := check("resistance", r.ID, m.ID); err != nil {
			return err
		}
	}

	for _, attack := range m.Attacks {
		if err := check("attack_type", attack.TypeID, m.ID); err != nil {
			return err
		}

		if err := check("attack_flavour", attack.FlavourID, m.ID); err != nil {
			return err
		}
	}

	return validateMonsterTileIDs(m)
}

func validateMonsterTileIDs(m MonsterDef) error {
	for _, tile := range []string{m.Tile.ID, m.CorpseTileID} {
		if tile == "0" {
			continue
		}

		if tile != "TILE_ERROR" && !strings.HasPrefix(tile, "TILEP_") &&
			!strings.HasPrefix(tile, "TILE_") {
			return fmt.Errorf("monster %s has invalid tile %q", m.ID, tile)
		}

		for _, r := range tile {
			if !(r >= 'A' &&
				r <= 'Z') &&
				!(r >= '0' &&
					r <= '9') &&
				r != '_' {
				return fmt.Errorf("monster %s has invalid tile %q", m.ID, tile)
			}
		}
	}

	return nil
}
