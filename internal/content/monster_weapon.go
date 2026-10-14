package content

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
)

// WeightedWeaponChoice preserves one ordered source choice. NUM_WEAPONS is
// the source's explicit no-weapon choice, not a usable item.
type WeightedWeaponChoice struct {
	ID     string `json:"id"`
	Weight int    `json:"weight"`
}

type MonsterWeaponPlus struct {
	Odds  int `json:"odds"`
	Min   int `json:"min"`
	Max   int `json:"max"`
	Rolls int `json:"rolls"`
}

type MonsterWeaponSpec struct {
	MonsterID      string                 `json:"monster_id"`
	SourceLine     int                    `json:"source_line"`
	SpecLine       int                    `json:"spec_line"`
	WeaponListLine int                    `json:"weapon_list_line"`
	BrandListLine  int                    `json:"brand_list_line"`
	Weapons        []WeightedWeaponChoice `json:"weapons"`
	Plus           MonsterWeaponPlus      `json:"plus"`
	Brands         []WeightedWeaponChoice `json:"brands"`
	GoodChance     int                    `json:"good_chance"`
}

type MonsterWeaponArtifact struct {
	SchemaVersion  int                 `json:"schema_version"`
	SourceRevision string              `json:"source_revision"`
	SourceFiles    []JobSourceFile     `json:"source_files"`
	Primary        []MonsterWeaponSpec `json:"primary"`
	Secondary      []MonsterWeaponSpec `json:"secondary"`
}

func (a MonsterWeaponArtifact) Validate() error {
	if a.SchemaVersion != 1 ||
		a.SourceRevision == "" ||
		len(a.SourceFiles) != 2 ||
		len(a.Primary) == 0 ||
		len(a.Secondary) == 0 {
		return fmt.Errorf("invalid monster weapon artifact metadata")
	}

	for _, table := range [][]MonsterWeaponSpec{a.Primary, a.Secondary} {
		seen := make(map[string]bool, len(table))

		for _, spec := range table {
			if !strings.HasPrefix(spec.MonsterID, "MONS_") ||
				seen[spec.MonsterID] ||
				spec.SourceLine <= 0 ||
				spec.SpecLine <= 0 ||
				spec.WeaponListLine <= 0 ||
				(len(spec.Brands) > 0 && spec.BrandListLine <= 0) ||
				len(spec.Weapons) == 0 ||
				spec.GoodChance < 0 ||
				spec.Plus.Odds < 0 ||
				spec.Plus.Rolls < 0 ||
				(spec.Plus.Odds > 0 &&
					spec.Plus.Min > spec.Plus.Max) {
				return fmt.Errorf("invalid monster weapon spec %s", spec.MonsterID)
			}

			seen[spec.MonsterID] = true

			for _, choice := range append(
				append([]WeightedWeaponChoice(nil), spec.Weapons...),
				spec.Brands...,
			) {
				if choice.ID == "" || choice.Weight <= 0 {
					return fmt.Errorf("invalid %s weapon choice %+v", spec.MonsterID, choice)
				}
			}
		}
	}

	return nil
}

// ValidateMonsterWeaponReferences reconciles generated IDs with committed
// content. Import and runtime share this check, so neither trusts raw source.
func ValidateMonsterWeaponReferences(
	catalog Catalog,
	artifact MonsterWeaponArtifact,
) error {
	brands, err := DefaultItemBrandIDs()

	if err != nil {
		return err
	}

	knownBrands := make(map[string]bool, len(brands))

	for _, brand := range brands {
		knownBrands[brand] = true
	}

	for _, table := range [][]MonsterWeaponSpec{artifact.Primary, artifact.Secondary} {
		for _, spec := range table {
			if _, err := catalog.Monster(spec.MonsterID); err != nil {
				return fmt.Errorf("mon-gear.cc:%d: %w", spec.SourceLine, err)
			}

			for _, choice := range spec.Weapons {
				if choice.ID == "NUM_WEAPONS" {
					continue
				}

				if _, err := catalog.Item(choice.ID); err != nil {
					return fmt.Errorf("mon-gear.cc:%d: %w", spec.SourceLine, err)
				}
			}

			for _, choice := range spec.Brands {
				if choice.ID != "NUM_SPECIAL_WEAPONS" &&
					!knownBrands[choice.ID] {
					return fmt.Errorf("mon-gear.cc:%d: unknown brand %s",
						spec.SourceLine, choice.ID)
				}
			}
		}
	}

	return nil
}

func attachDefaultMonsterWeapons(catalog Catalog, data []byte) (Catalog, error) {
	const pinnedArtifactSHA256 = "b374403155ca2c6a01ad988eac78a474a5cd10228158fa59e9ab53d3d0e60176"
	hash := sha256.Sum256(data)

	if hex.EncodeToString(hash[:]) != pinnedArtifactSHA256 {
		return Catalog{}, fmt.Errorf("monster weapons differ from pinned content")
	}

	var artifact MonsterWeaponArtifact

	if err := decodeArtifact(data, "monster weapons", &artifact); err != nil {
		return Catalog{}, err
	}

	if err := artifact.Validate(); err != nil {
		return Catalog{}, err
	}

	if artifact.SourceRevision != catalog.SourceRevision() ||
		len(artifact.Primary) != 162 ||
		len(artifact.Secondary) != 16 {
		return Catalog{}, fmt.Errorf("monster weapon catalog has incomplete pinned coverage")
	}

	paths, err := validSourceFiles(artifact.SourceFiles, "monster weapon")

	if err != nil {
		return Catalog{}, err
	}

	for _, name := range []string{"mon-gear.cc", "tag-version.h"} {
		if _, found := paths["crawl-ref/source/"+name]; !found {
			return Catalog{}, fmt.Errorf("monster weapon catalog lacks source %s", name)
		}
	}

	if err := ValidateMonsterWeaponReferences(catalog, artifact); err != nil {
		return Catalog{}, err
	}

	catalog.primaryMonsterWeapons = make(map[string]MonsterWeaponSpec, len(artifact.Primary))
	catalog.secondaryMonsterWeapons = make(map[string]MonsterWeaponSpec, len(artifact.Secondary))

	for _, spec := range artifact.Primary {
		catalog.primaryMonsterWeapons[spec.MonsterID] = spec.clone()
	}

	for _, spec := range artifact.Secondary {
		catalog.secondaryMonsterWeapons[spec.MonsterID] = spec.clone()
	}

	if err := catalog.Validate(); err != nil {
		return Catalog{}, err
	}

	return catalog, nil
}

func (s MonsterWeaponSpec) clone() MonsterWeaponSpec {
	s.Weapons = append([]WeightedWeaponChoice(nil), s.Weapons...)
	s.Brands = append([]WeightedWeaponChoice(nil), s.Brands...)

	return s
}

// MonsterWeapon returns a copied declarative loadout. The bool is false for
// monsters without a source table entry; switch-based rules are separate.
func (c Catalog) MonsterWeapon(id string, secondary bool) (MonsterWeaponSpec, bool) {
	table := c.primaryMonsterWeapons

	if secondary {
		table = c.secondaryMonsterWeapons
	}

	spec, found := table[id]

	return spec.clone(), found
}
