package content

import (
	"fmt"
	"regexp"
	"strings"
)

type SpellStatus string

const (
	SpellDefined  SpellStatus = "defined"
	SpellRemoved  SpellStatus = "removed"
	SpellSentinel SpellStatus = "sentinel"
)

type SpellDef struct {
	ID           string      `json:"id"`
	NumericID    int         `json:"numeric_id"`
	Status       SpellStatus `json:"status"`
	Name         string      `json:"name"`
	Schools      []string    `json:"schools"`
	Flags        []string    `json:"flags"`
	Level        int         `json:"level"`
	PowerCap     int         `json:"power_cap"`
	MinRangeExpr string      `json:"min_range_expr"`
	MaxRangeExpr string      `json:"max_range_expr"`
	Noise        int         `json:"noise"`
	EffectNoise  int         `json:"effect_noise"`
	TileID       string      `json:"tile_id"`
	EnumLine     int         `json:"enum_line"`
	SourcePath   string      `json:"source_path"`
	SourceLine   int         `json:"source_line"`
}

func (s SpellDef) clone() SpellDef {
	s.Schools = append([]string(nil), s.Schools...)
	s.Flags = append([]string(nil), s.Flags...)
	return s
}

var spellIDPattern = regexp.MustCompile(`^SPELL_[A-Z0-9_]+$`)
var spellRangePattern = regexp.MustCompile(`^[A-Z0-9_+*/() -]+$`)
var spellTilePattern = regexp.MustCompile(`^TILEG_[A-Z0-9_]+$`)

func (s SpellDef) validate() error {
	if !spellIDPattern.MatchString(s.ID) || s.NumericID < 0 || s.Name == "" || strings.TrimSpace(s.Name) != s.Name ||
		s.Level < 1 || s.Level > 9 || s.PowerCap < 0 || s.Noise < 0 || s.EffectNoise < 0 ||
		!spellRangePattern.MatchString(s.MinRangeExpr) || !spellRangePattern.MatchString(s.MaxRangeExpr) ||
		!spellTilePattern.MatchString(s.TileID) || s.EnumLine <= 0 ||
		s.SourcePath != "crawl-ref/source/spl-data.h" || s.SourceLine <= 0 {
		return fmt.Errorf("invalid spell definition %s", s.ID)
	}

	if s.ID == "SPELL_NO_SPELL" && s.Status != SpellSentinel || s.ID != "SPELL_NO_SPELL" &&
		s.Status != SpellDefined && s.Status != SpellRemoved {
		return fmt.Errorf("invalid spell status for %s", s.ID)
	}

	if len(s.Schools) == 0 || len(s.Flags) == 0 {
		return fmt.Errorf("spell %s lacks schools or flags", s.ID)
	}

	for _, value := range s.Schools {
		if value == "" {
			return fmt.Errorf("spell %s has empty school", s.ID)
		}
	}

	for _, value := range s.Flags {
		if value == "" {
			return fmt.Errorf("spell %s has empty flag", s.ID)
		}
	}

	return nil
}

type SpellArtifact struct {
	SchemaVersion   int             `json:"schema_version"`
	SourceRevision  string          `json:"source_revision"`
	TagMajorVersion int             `json:"tag_major_version"`
	SourceFiles     []JobSourceFile `json:"source_files"`
	Spells          []SpellDef      `json:"spells"`
}

func (a SpellArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision != sourceRevision || a.TagMajorVersion != 34 ||
		len(a.SourceFiles) == 0 || len(a.Spells) == 0 {
		return fmt.Errorf("invalid spell artifact header or empty catalog")
	}

	seen := map[string]bool{}
	for i, spell := range a.Spells {
		if spell.NumericID != i || seen[spell.ID] {
			return fmt.Errorf("duplicate or out-of-order spell %s", spell.ID)
		}

		if err := spell.validate(); err != nil {
			return err
		}

		seen[spell.ID] = true
	}

	return nil
}
