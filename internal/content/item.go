package content

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
)

// ItemIdentity is a concrete class/subtype pair from the pinned enum source.
// It can exist without a usable definition.
type ItemIdentity struct {
	ID                string `json:"id"`
	ClassID           string `json:"class_id"`
	ClassValue        int    `json:"class_value"`
	SubtypeValue      int    `json:"subtype_value"`
	SourcePath        string `json:"source_path"`
	SourceLine        int    `json:"source_line"`
	ExplicitlyRemoved bool   `json:"explicitly_removed"`
}

type ItemAlias struct {
	ID           string `json:"id"`
	TargetID     string `json:"target_id"`
	ClassID      string `json:"class_id"`
	NumericValue int    `json:"numeric_value"`
	SourcePath   string `json:"source_path"`
	SourceLine   int    `json:"source_line"`
}

type ItemName struct {
	Text       string `json:"text"`
	Kind       string `json:"kind"`
	SourcePath string `json:"source_path"`
	SourceLine int    `json:"source_line"`
}

type ItemEvidence struct {
	NameSource     string `json:"name_source,omitempty"`
	NameLine       int    `json:"name_line,omitempty"`
	PropertySource string `json:"property_source,omitempty"`
	PropertyLine   int    `json:"property_line,omitempty"`
}

type ItemFlag struct {
	ID    string `json:"id"`
	Level int    `json:"level"`
}

type ArmourProperties struct {
	AC            int        `json:"ac"`
	EV            int        `json:"ev"`
	Price         int        `json:"price"`
	AcquireWeight int        `json:"acquire_weight"`
	SlotID        string     `json:"slot_id"`
	FitMinID      string     `json:"fit_min_id"`
	FitMaxID      string     `json:"fit_max_id"`
	Mundane       bool       `json:"mundane"`
	Flags         []ItemFlag `json:"flags"`
}

type ItemBrandWeight struct {
	BrandID string `json:"brand_id"`
	Weight  int    `json:"weight"`
}

type WeaponProperties struct {
	Damage        int               `json:"damage"`
	Hit           int               `json:"hit"`
	Speed         int               `json:"speed"`
	Commonness    int               `json:"commonness"`
	AcquireWeight int               `json:"acquire_weight"`
	Price         int               `json:"price"`
	SkillID       string            `json:"skill_id"`
	Min2HSizeID   string            `json:"min_2h_size_id"`
	Min1HSizeID   string            `json:"min_1h_size_id"`
	AmmoID        string            `json:"ammo_id"`
	DamageFlags   []string          `json:"damage_flags"`
	BrandWeights  []ItemBrandWeight `json:"brand_weights"`
}

type MissileProperties struct {
	Damage    int `json:"damage"`
	MulchRate int `json:"mulch_rate"`
	Price     int `json:"price"`
}

type FoodProperties struct {
	NormalNutrition    int `json:"normal_nutrition"`
	CarnivoreNutrition int `json:"carnivore_nutrition"`
	HerbivoreNutrition int `json:"herbivore_nutrition"`
}

// ItemDef contains immutable base-kind data. Live per-instance fields live in ECS.
type ItemDef struct {
	ID                string             `json:"id"`
	Name              string             `json:"name"`
	PropertyName      string             `json:"property_name,omitempty"`
	Glyph             rune               `json:"glyph"`
	Class             string             `json:"class"`
	ClassValue        int                `json:"class_value"`
	SubtypeValue      int                `json:"subtype_value"`
	Slot              string             `json:"slot,omitempty"`
	WeaponSkill       string             `json:"weapon_skill,omitempty"`
	Stackable         bool               `json:"stackable"`
	Naming            ItemName           `json:"naming"`
	Evidence          ItemEvidence       `json:"evidence"`
	ExplicitlyRemoved bool               `json:"explicitly_removed"`
	Armour            *ArmourProperties  `json:"armour,omitempty"`
	Weapon            *WeaponProperties  `json:"weapon,omitempty"`
	Missile           *MissileProperties `json:"missile,omitempty"`
	Food              *FoodProperties    `json:"food,omitempty"`
}

type ItemVocabulary struct {
	Slots       []string `json:"slots"`
	Skills      []string `json:"skills"`
	Sizes       []string `json:"sizes"`
	Ammo        []string `json:"ammo"`
	DamageFlags []string `json:"damage_flags"`
	Brands      []string `json:"brands"`
	ArmourFlags []string `json:"armour_flags"`
}

type ItemArtifact struct {
	SchemaVersion   int             `json:"schema_version"`
	SourceRevision  string          `json:"source_revision"`
	TagMajorVersion int             `json:"tag_major_version"`
	SourceFiles     []JobSourceFile `json:"source_files"`
	Items           []ItemDef       `json:"items"`
}

type ItemIdentityManifest struct {
	SchemaVersion     int             `json:"schema_version"`
	SourceRevision    string          `json:"source_revision"`
	TagMajorVersion   int             `json:"tag_major_version"`
	SourceFiles       []JobSourceFile `json:"source_files"`
	Identities        []ItemIdentity  `json:"identities"`
	Aliases           []ItemAlias     `json:"aliases"`
	Vocabulary        ItemVocabulary  `json:"vocabulary"`
	DefinitionsSHA256 string          `json:"definitions_sha256"`
}

func (d ItemDef) clone() ItemDef {
	if d.Armour != nil {
		copy := *d.Armour
		copy.Flags = append([]ItemFlag(nil), copy.Flags...)
		d.Armour = &copy
	}
	if d.Weapon != nil {
		copy := *d.Weapon
		copy.DamageFlags = append([]string(nil), copy.DamageFlags...)
		copy.BrandWeights = append([]ItemBrandWeight(nil), copy.BrandWeights...)
		d.Weapon = &copy
	}
	if d.Missile != nil {
		copy := *d.Missile
		d.Missile = &copy
	}
	if d.Food != nil {
		copy := *d.Food
		d.Food = &copy
	}
	return d
}

func (d ItemDef) validate() error {
	if d.ID == "" || d.Name == "" || d.Glyph == 0 {
		return fmt.Errorf("item %s has empty ID, name, or glyph", d.ID)
	}
	prefix := map[string]string{
		"OBJ_WEAPONS":    "WPN_",
		"OBJ_ARMOUR":     "ARM_",
		"OBJ_MISSILES":   "MI_",
		"OBJ_POTIONS":    "POT_",
		"OBJ_SCROLLS":    "SCR_",
		"OBJ_WANDS":      "WAND_",
		"OBJ_MISCELLANY": "MISC_",
		"OBJ_FOOD":       "FOOD_",
		"OBJ_JEWELLERY":  "",
		"OBJ_BOOKS":      "BOOK_",
		"OBJ_STAVES":     "STAFF_",
		"OBJ_ORBS":       "ORB_",
		"OBJ_CORPSES":    "CORPSE_",
		"OBJ_GOLD":       "OBJ_GOLD",
		"OBJ_RODS":       "ROD_",
		"OBJ_RUNES":      "RUNE_",
	}[d.Class]
	if _, known := map[string]bool{
		"OBJ_WEAPONS":    true,
		"OBJ_ARMOUR":     true,
		"OBJ_MISSILES":   true,
		"OBJ_POTIONS":    true,
		"OBJ_SCROLLS":    true,
		"OBJ_WANDS":      true,
		"OBJ_MISCELLANY": true,
		"OBJ_FOOD":       true,
		"OBJ_JEWELLERY":  true,
		"OBJ_BOOKS":      true,
		"OBJ_STAVES":     true,
		"OBJ_ORBS":       true,
		"OBJ_CORPSES":    true,
		"OBJ_GOLD":       true,
		"OBJ_RODS":       true,
		"OBJ_RUNES":      true,
	}[d.Class]; !known || (prefix != "" && !strings.HasPrefix(d.ID, prefix)) {
		return fmt.Errorf("item %s has invalid class %s", d.ID, d.Class)
	}
	switch d.Class {
	case "OBJ_WEAPONS":
		if d.Slot != "weapon" || !strings.HasPrefix(d.WeaponSkill, "SK_") || d.Stackable {
			return fmt.Errorf("item %s has invalid weapon slot or skill", d.ID)
		}
	case "OBJ_ARMOUR":
		if !strings.Contains(" body shield head cloak gloves boots ", " "+d.Slot+" ") || d.WeaponSkill != "" || d.Stackable {
			return fmt.Errorf("item %s has invalid armour slot or skill", d.ID)
		}
	default:
		if d.Slot != "" || d.WeaponSkill != "" {
			return fmt.Errorf("item %s has invalid slot or skill", d.ID)
		}
		if (d.Class == "OBJ_MISSILES" || d.Class == "OBJ_POTIONS" || d.Class == "OBJ_SCROLLS") && !d.Stackable {
			return fmt.Errorf("item %s must be stackable", d.ID)
		}
	}
	if d.Naming.Text == "" || d.Naming.SourcePath == "" || d.Naming.SourceLine <= 0 {
		return fmt.Errorf("item %s has invalid naming provenance", d.ID)
	}
	switch d.Naming.Kind {
	case "static", "manual_skill", "corpse_monster":
	default:
		return fmt.Errorf("item %s has invalid naming kind %q", d.ID, d.Naming.Kind)
	}
	if d.ClassValue < 0 || d.SubtypeValue < 0 {
		return fmt.Errorf("item %s has invalid numeric identity", d.ID)
	}
	propertyCount := 0
	for _, present := range []bool{d.Armour != nil, d.Weapon != nil, d.Missile != nil, d.Food != nil} {
		if present {
			propertyCount++
		}
	}
	if propertyCount > 1 || (d.Armour != nil && d.Class != "OBJ_ARMOUR") || (d.Weapon != nil &&
		d.Class != "OBJ_WEAPONS") || (d.Missile != nil && d.Class != "OBJ_MISSILES") || (d.Food != nil &&
		d.Class != "OBJ_FOOD") {
		return fmt.Errorf("item %s has wrong class property shape", d.ID)
	}
	if (d.Food != nil && d.PropertyName == "") || (d.Food == nil && d.PropertyName != "") {
		return fmt.Errorf("item %s has invalid food property name", d.ID)
	}
	if d.Weapon != nil {
		previous := ""
		for _, brand := range d.Weapon.BrandWeights {
			if brand.BrandID <= previous || brand.Weight < 0 {
				return fmt.Errorf("item %s has invalid brand weights", d.ID)
			}
			previous = brand.BrandID
		}
	}
	return nil
}

func (m ItemIdentityManifest) Validate() error {
	if m.SchemaVersion != 1 || m.SourceRevision == "" || m.TagMajorVersion != 34 {
		return fmt.Errorf("unsupported item identity manifest metadata")
	}
	if _, err := validSourceFiles(m.SourceFiles, "item identity"); err != nil {
		return err
	}
	if len(m.DefinitionsSHA256) != 64 {
		return fmt.Errorf("item identity manifest has no definitions hash")
	}
	if _, err := hex.DecodeString(m.DefinitionsSHA256); err != nil {
		return fmt.Errorf("invalid item definitions hash: %w", err)
	}
	seen := map[string]bool{}
	previousClass, previousSubtype := -1, -1
	for _, identity := range m.Identities {
		if identity.ID == "" || identity.ClassID == "" || identity.ClassValue < 0 ||
			identity.SubtypeValue < 0 || identity.SourcePath == "" || identity.SourceLine <= 0 || seen[identity.ID] {
			return fmt.Errorf("invalid or duplicate item identity %q", identity.ID)
		}
		seen[identity.ID] = true
		if identity.ClassValue < previousClass || (identity.ClassValue == previousClass &&
			identity.SubtypeValue <= previousSubtype) {
			return fmt.Errorf("item identities are not in numeric class/subtype order")
		}
		previousClass, previousSubtype = identity.ClassValue, identity.SubtypeValue
	}
	for _, alias := range m.Aliases {
		if alias.ID == "" || alias.TargetID == "" || alias.SourcePath == "" || alias.SourceLine <= 0 || seen[alias.ID] {
			return fmt.Errorf("invalid or duplicate item alias %q", alias.ID)
		}
		seen[alias.ID] = true
	}
	for _, symbols := range [][]string{
		m.Vocabulary.Slots,
		m.Vocabulary.Skills,
		m.Vocabulary.Sizes,
		m.Vocabulary.Ammo,
		m.Vocabulary.DamageFlags,
		m.Vocabulary.Brands,
		m.Vocabulary.ArmourFlags,
	} {
		if !sort.StringsAreSorted(symbols) {
			return fmt.Errorf("unsorted item vocabulary")
		}
		for i, symbol := range symbols {
			if symbol == "" || (i > 0 && symbol == symbols[i-1]) {
				return fmt.Errorf("duplicate or empty item vocabulary symbol %q", symbol)
			}
		}
	}
	return nil
}

func (a ItemArtifact) Validate(manifest ItemIdentityManifest) error {
	if err := manifest.Validate(); err != nil {
		return err
	}
	if a.SchemaVersion != 1 || a.SourceRevision != manifest.SourceRevision ||
		a.TagMajorVersion != manifest.TagMajorVersion {
		return fmt.Errorf("item artifact metadata differs from identity manifest")
	}
	files, err := validSourceFiles(a.SourceFiles, "item")
	if err != nil {
		return err
	}
	for _, file := range manifest.SourceFiles {
		if files[file.Path] != file.SHA256 {
			return fmt.Errorf("item artifact source hash differs for %s", file.Path)
		}
	}
	identities := make(map[string]ItemIdentity, len(manifest.Identities))
	for _, identity := range manifest.Identities {
		identities[identity.ID] = identity
	}
	seen := map[string]bool{}
	previousClass, previousSubtype := -1, -1
	for _, item := range a.Items {
		identity, ok := identities[item.ID]
		if !ok || seen[item.ID] || identity.ClassID != item.Class ||
			identity.ClassValue != item.ClassValue || identity.SubtypeValue != item.SubtypeValue ||
			identity.ExplicitlyRemoved != item.ExplicitlyRemoved {
			return fmt.Errorf("item %s differs from independent identity manifest", item.ID)
		}
		if err := item.validate(); err != nil {
			return err
		}
		if item.ClassValue < previousClass || (item.ClassValue == previousClass && item.SubtypeValue <= previousSubtype) {
			return fmt.Errorf("item definitions are not in numeric class/subtype order")
		}
		previousClass, previousSubtype = item.ClassValue, item.SubtypeValue
		if item.Name != item.Naming.Text || item.Naming.Kind == "" || files[item.Naming.SourcePath] == "" {
			return fmt.Errorf("item %s has invalid naming evidence", item.ID)
		}
		if item.Armour != nil || item.Weapon != nil || item.Missile != nil || item.Food != nil {
			if files[item.Evidence.PropertySource] == "" || item.Evidence.PropertyLine <= 0 {
				return fmt.Errorf("item %s has invalid property evidence", item.ID)
			}
		}
		if err := item.validateVocabulary(manifest.Vocabulary); err != nil {
			return err
		}
		seen[item.ID] = true
	}
	for _, identity := range manifest.Identities {
		if !identity.ExplicitlyRemoved && !seen[identity.ID] {
			return fmt.Errorf("item %s is missing a definition", identity.ID)
		}
		if (identity.ClassID == "OBJ_WEAPONS" || identity.ClassID == "OBJ_ARMOUR" ||
			identity.ClassID == "OBJ_MISSILES" || identity.ClassID == "OBJ_FOOD") && !seen[identity.ID] {
			return fmt.Errorf("item %s is missing its property row", identity.ID)
		}
	}
	encoded, err := json.Marshal(a.Items)
	if err != nil {
		return fmt.Errorf("encode item definitions for validation: %w", err)
	}
	hash := sha256.Sum256(encoded)
	if hex.EncodeToString(hash[:]) != manifest.DefinitionsSHA256 {
		return fmt.Errorf("item definitions differ from identity manifest hash")
	}
	return nil
}

func vocabularyHas(ids []string, id string) bool {
	i := sort.SearchStrings(ids, id)
	return i < len(ids) && ids[i] == id
}

func (d ItemDef) validateVocabulary(v ItemVocabulary) error {
	switch d.Class {
	case "OBJ_ARMOUR":
		if d.Armour == nil || !vocabularyHas(v.Slots, d.Armour.SlotID) ||
			!vocabularyHas(v.Sizes, d.Armour.FitMinID) || !vocabularyHas(v.Sizes, d.Armour.FitMaxID) {
			return fmt.Errorf("item %s has incomplete or unknown armour properties", d.ID)
		}
		for _, flag := range d.Armour.Flags {
			if !vocabularyHas(v.ArmourFlags, flag.ID) || flag.Level == 0 {
				return fmt.Errorf("item %s has unknown armour flag %s", d.ID, flag.ID)
			}
		}
	case "OBJ_WEAPONS":
		if d.Weapon == nil || !vocabularyHas(v.Skills, d.Weapon.SkillID) ||
			!vocabularyHas(v.Sizes, d.Weapon.Min2HSizeID) || !vocabularyHas(v.Sizes, d.Weapon.Min1HSizeID) ||
			!vocabularyHas(v.Ammo, d.Weapon.AmmoID) || d.Weapon.SkillID != d.WeaponSkill {
			return fmt.Errorf("item %s has incomplete or unknown weapon properties", d.ID)
		}
		for _, flag := range d.Weapon.DamageFlags {
			if !vocabularyHas(v.DamageFlags, flag) {
				return fmt.Errorf("item %s has unknown damage flag %s", d.ID, flag)
			}
		}
		for _, brand := range d.Weapon.BrandWeights {
			if !vocabularyHas(v.Brands, brand.BrandID) {
				return fmt.Errorf("item %s has unknown brand %s", d.ID, brand.BrandID)
			}
		}
	case "OBJ_MISSILES":
		if d.Missile == nil {
			return fmt.Errorf("item %s lacks missile properties", d.ID)
		}
	case "OBJ_FOOD":
		if d.Food == nil {
			return fmt.Errorf("item %s lacks food properties", d.ID)
		}
	default:
		if d.Armour != nil || d.Weapon != nil || d.Missile != nil || d.Food != nil {
			return fmt.Errorf("item %s has invented class properties", d.ID)
		}
	}
	return nil
}

func (c Catalog) ItemIdentity(id string) (ItemIdentity, error) {
	identity, found := c.itemIdentities[id]
	if !found {
		return ItemIdentity{}, fmt.Errorf("unknown item identity %q", id)
	}
	return identity, nil
}

func (c Catalog) ItemIDs() []string {
	ids := make([]string, 0, len(c.itemIdentities))
	for id := range c.itemIdentities {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	return ids
}
