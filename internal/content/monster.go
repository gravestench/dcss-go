package content

import (
	"encoding/json"
	"fmt"
	"reflect"
	"sort"
	"strings"
)

// MarshalJSON keeps placeholder records free of live gameplay fields.
func (m MonsterDef) MarshalJSON() ([]byte, error) {
	if m.Status == MonsterDefined {
		type record MonsterDef

		return json.Marshal(record(m))
	}

	return json.Marshal(struct {
		ID         string        `json:"id"`
		Status     MonsterStatus `json:"status"`
		SourcePath string        `json:"source_path"`
		SourceLine int           `json:"source_line"`
		Name       string        `json:"name,omitempty"`
	}{
		ID:         m.ID,
		Status:     m.Status,
		SourcePath: m.SourcePath,
		SourceLine: m.SourceLine,
		Name:       m.Name,
	})
}

type MonsterStatus string

const (
	MonsterDefined  MonsterStatus = "defined"
	MonsterRemoved  MonsterStatus = "removed"
	MonsterEnumOnly MonsterStatus = "enum_only"
)

type MonsterAttack struct {
	TypeID    string `json:"type_id"`
	FlavourID string `json:"flavour_id"`
	Damage    int    `json:"damage"`
}

type MonsterResistance struct {
	ID    string `json:"id"`
	Level int    `json:"level"`
}

type MonsterEnergy struct {
	Move int `json:"move"`
	Swim int `json:"swim"`

	Attack  int `json:"attack"`
	Missile int `json:"missile"`
	Spell   int `json:"spell"`
	Special int `json:"special"`

	Item          int `json:"item"`
	PickupPercent int `json:"pickup_percent"`
}

type MonsterTile struct {
	ID          string `json:"id"`
	VariationID string `json:"variation_id"`
}

// MonsterDef is a source-traced class definition, never a live monster.
// Removed and enum-only records carry identity and provenance, not gameplay fields.
type MonsterDef struct {
	ID         string        `json:"id"`
	Status     MonsterStatus `json:"status"`
	SourcePath string        `json:"source_path"`
	SourceLine int           `json:"source_line"`

	Name     string `json:"name,omitempty"`
	Glyph    rune   `json:"glyph,omitempty"`
	ColourID string `json:"colour_id,omitempty"`

	Flags       []string            `json:"flags,omitempty"`
	Resistances []MonsterResistance `json:"resistances,omitempty"`
	XPModifier  int                 `json:"xp_modifier,omitempty"`
	GenusID     string              `json:"genus_id,omitempty"`
	SpeciesID   string              `json:"species_id,omitempty"`
	Holiness    []string            `json:"holiness,omitempty"`
	Willpower   int                 `json:"willpower,omitempty"`

	Attacks      [4]MonsterAttack `json:"attacks,omitempty"`
	HD           int              `json:"hd,omitempty"`
	AverageHP10x int              `json:"average_hp_10x,omitempty"`
	AC           int              `json:"ac,omitempty"`
	EV           int              `json:"ev,omitempty"`
	SpellbookID  string           `json:"spellbook_id,omitempty"`

	LeavesCorpse   bool          `json:"leaves_corpse,omitempty"`
	ShoutID        string        `json:"shout_id,omitempty"`
	IntelligenceID string        `json:"intelligence_id,omitempty"`
	HabitatID      string        `json:"habitat_id,omitempty"`
	Speed          int           `json:"speed,omitempty"`
	Energy         MonsterEnergy `json:"energy,omitempty"`
	ItemUseID      string        `json:"item_use_id,omitempty"`
	SizeID         string        `json:"size_id,omitempty"`
	ShapeID        string        `json:"shape_id,omitempty"`

	Tile         MonsterTile `json:"tile,omitempty"`
	CorpseTileID string      `json:"corpse_tile_id,omitempty"`
}

type MonsterArtifact struct {
	SchemaVersion   int             `json:"schema_version"`
	SourceRevision  string          `json:"source_revision"`
	TagMajorVersion int             `json:"tag_major_version"`
	SourceFiles     []JobSourceFile `json:"source_files"`
	Monsters        []MonsterDef    `json:"monsters"`
}

func (m MonsterDef) clone() MonsterDef {
	m.Flags = append([]string(nil), m.Flags...)
	m.Holiness = append([]string(nil), m.Holiness...)
	m.Resistances = append([]MonsterResistance(nil), m.Resistances...)

	return m
}

func (m MonsterDef) validate() error {
	if !strings.HasPrefix(m.ID, "MONS_") || m.SourcePath == "" || m.SourceLine < 0 {
		return fmt.Errorf("invalid monster identity %q", m.ID)
	}

	switch m.Status {
	case MonsterDefined:
		if m.SourceLine == 0 ||
			m.ColourID == "" ||
			m.GenusID == "" ||
			m.SpeciesID == "" ||
			m.SpellbookID == "" ||
			m.ShoutID == "" ||
			m.IntelligenceID == "" ||
			m.HabitatID == "" ||
			m.ItemUseID == "" ||
			m.SizeID == "" ||
			m.ShapeID == "" ||
			m.Tile.ID == "" ||
			m.Tile.VariationID == "" || m.CorpseTileID == "" || len(m.Holiness) == 0 {
			return fmt.Errorf("incomplete monster definition %s", m.ID)
		}

		for _, attack := range m.Attacks {
			if !strings.HasPrefix(attack.TypeID, "AT_") ||
				!strings.HasPrefix(attack.FlavourID, "AF_") || attack.Damage < 0 {
				return fmt.Errorf("monster %s has invalid attack", m.ID)
			}
		}

		for _, flag := range m.Flags {
			if !strings.HasPrefix(flag, "M_") {
				return fmt.Errorf("monster %s has invalid flag %q", m.ID, flag)
			}
		}

		for _, holy := range m.Holiness {
			if !strings.HasPrefix(holy, "MH_") {
				return fmt.Errorf("monster %s has invalid holiness %q", m.ID, holy)
			}
		}

		for _, resistance := range m.Resistances {
			if !strings.HasPrefix(resistance.ID, "MR_") || resistance.Level == 0 {
				return fmt.Errorf("monster %s has invalid resistance %q", m.ID, resistance.ID)
			}
		}

	case MonsterRemoved, MonsterEnumOnly:
		identity := MonsterDef{
			ID:         m.ID,
			Status:     m.Status,
			SourcePath: m.SourcePath,
			SourceLine: m.SourceLine,
			Name:       m.Name,
		}

		if !reflect.DeepEqual(m, identity) {
			return fmt.Errorf("non-live monster %s has gameplay fields", m.ID)
		}

	default:
		return fmt.Errorf("monster %s has unknown status %q", m.ID, m.Status)
	}

	return nil
}

func (a MonsterArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision == "" || a.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported monster artifact metadata")
	}

	previous := ""

	for _, monster := range a.Monsters {
		if monster.ID <= previous {
			return fmt.Errorf("duplicate or unsorted monster ID %q", monster.ID)
		}

		if err := monster.validate(); err != nil {
			return err
		}

		previous = monster.ID
	}

	return nil
}

func (c Catalog) MonsterStatus(id string) (MonsterStatus, error) {
	m, ok := c.monsters[id]

	if !ok {
		return "", fmt.Errorf("unknown monster ID %q", id)
	}

	return m.Status, nil
}

func (c Catalog) MonsterIDs() []string {
	ids := make([]string, 0, len(c.monsters))

	for id := range c.monsters {
		ids = append(ids, id)
	}

	sort.Strings(ids)

	return ids
}
