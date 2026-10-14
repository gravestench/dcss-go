package content

import (
	"fmt"
	"regexp"
	"slices"
)

// DungeonPopEntry preserves one source population row. Duplicate monster IDs
// carry distinct depth bands and remain separate entries.
type DungeonPopEntry struct {
	MinDepth   int    `json:"min_depth"`
	MaxDepth   int    `json:"max_depth"`
	Rarity     int    `json:"rarity"`
	Curve      string `json:"curve"`
	MonsterID  string `json:"monster_id"`
	SourceLine int    `json:"source_line"`
}

type DungeonPopulationArtifact struct {
	SchemaVersion   int               `json:"schema_version"`
	SourceRevision  string            `json:"source_revision"`
	TagMajorVersion int               `json:"tag_major_version"`
	SourceFiles     []JobSourceFile   `json:"source_files"`
	Rows            []DungeonPopEntry `json:"rows"`
}

var populationMonsterID = regexp.MustCompile(`^MONS_[A-Z0-9_]+$`)

func (entry DungeonPopEntry) validate() error {
	if entry.MinDepth < 0 || entry.MaxDepth < entry.MinDepth || entry.Rarity <= 0 ||
		entry.SourceLine <= 0 || !populationMonsterID.MatchString(entry.MonsterID) {
		return fmt.Errorf("invalid Dungeon population row %+v", entry)
	}

	switch entry.Curve {
	case "FLAT", "SEMI", "PEAK", "RISE", "FALL":
		return nil

	default:
		return fmt.Errorf("invalid Dungeon population curve %q", entry.Curve)
	}
}

func (artifact DungeonPopulationArtifact) Validate() error {
	if artifact.SchemaVersion != 1 || artifact.SourceRevision != sourceRevision ||
		artifact.TagMajorVersion != 34 || len(artifact.SourceFiles) == 0 || len(artifact.Rows) == 0 {
		return fmt.Errorf("invalid Dungeon population metadata")
	}

	if _, err := validSourceFiles(artifact.SourceFiles, "Dungeon population"); err != nil {
		return err
	}

	previousLine := 0

	for _, entry := range artifact.Rows {
		if err := entry.validate(); err != nil {
			return err
		}

		if entry.SourceLine <= previousLine {
			return fmt.Errorf("Dungeon population rows are out of source order")
		}

		previousLine = entry.SourceLine
	}

	return nil
}

// WeightAtDepth follows random-pick.h's integer 2520 scale. Rows outside
// their depth range do not enter the normal picker.
func (entry DungeonPopEntry) WeightAtDepth(depth int) int {
	if depth < entry.MinDepth || depth > entry.MaxDepth {
		return 0
	}

	rarity := entry.Rarity * 2520
	length := entry.MaxDepth - entry.MinDepth

	switch entry.Curve {
	case "FLAT":
		return rarity

	case "SEMI":
		if length == 0 {
			length = 2
		} else {
			length *= 2
		}

		return rarity * (length - absInt(entry.MinDepth+entry.MaxDepth-2*depth)) / length

	case "PEAK":
		length += 2

		return rarity * (length - absInt(entry.MinDepth+entry.MaxDepth-2*depth)) / length

	case "RISE":
		return rarity * (depth - entry.MinDepth + 1) / (length + 1)

	case "FALL":
		return rarity * (entry.MaxDepth - depth + 1) / (length + 1)

	default:
		return 0
	}
}

func absInt(value int) int {
	if value < 0 {
		return -value
	}

	return value
}

func (c Catalog) DungeonPopulation() []DungeonPopEntry {
	return slices.Clone(c.dungeonPopulation)
}
