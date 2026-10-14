package itemimport

import (
	"fmt"

	"dcrawl-go/internal/content"
)

// itemSourceViews joins independently imported source facts by class and ID.
// The maps remain immutable while each catalog item is assembled.
type itemSourceViews struct {
	properties map[itemKey]itemPropertyRow
	names      map[itemKey]content.ItemName
	glyphs     map[itemKey]rune
}

func joinItemViews(
	identities []content.ItemIdentity,
	rows map[itemKey]itemPropertyRow,
	names map[itemKey]content.ItemName,
	glyphs map[itemKey]rune,
) ([]content.ItemDef, error) {
	views := itemSourceViews{
		properties: rows,
		names:      names,
		glyphs:     glyphs,
	}

	if err := views.validateKeys(identities); err != nil {
		return nil, err
	}

	items := make([]content.ItemDef, 0, len(identities))

	for _, identity := range identities {
		item, keep, err := views.buildItem(identity)

		if err != nil {
			return nil, err
		}

		if keep {
			items = append(items, item)
		}
	}

	return items, nil
}

func (v itemSourceViews) validateKeys(identities []content.ItemIdentity) error {
	known := make(map[itemKey]bool, len(identities))

	for _, id := range identities {
		key := itemKey{
			ClassID:   id.ClassID,
			SubtypeID: id.ID,
		}

		if known[key] {
			return fmt.Errorf("duplicate identity %s/%s", key.ClassID, key.SubtypeID)
		}

		known[key] = true
	}

	for key := range v.properties {
		if !known[key] {
			return fmt.Errorf("property row without identity: %s/%s", key.ClassID, key.SubtypeID)
		}
	}

	for key := range v.names {
		if !known[key] {
			return fmt.Errorf("name without identity: %s/%s", key.ClassID, key.SubtypeID)
		}
	}

	for key := range v.glyphs {
		if !known[key] {
			return fmt.Errorf("glyph without identity: %s/%s", key.ClassID, key.SubtypeID)
		}
	}

	return nil
}

func (v itemSourceViews) buildItem(identity content.ItemIdentity) (content.ItemDef, bool, error) {
	key := itemKey{
		ClassID:   identity.ClassID,
		SubtypeID: identity.ID,
	}

	row, hasRow := v.properties[key]
	glyph, hasGlyph := v.glyphs[key]

	if !hasGlyph || glyph == 0 {
		return content.ItemDef{}, false, fmt.Errorf("missing ASCII glyph for %s", identity.ID)
	}

	expectsRow := requiresPropertyRow(identity.ClassID)

	if expectsRow && !hasRow {
		return content.ItemDef{}, false, fmt.Errorf("missing property row for %s", identity.ID)
	}

	if !expectsRow && hasRow {
		return content.ItemDef{}, false, fmt.Errorf("unexpected property row for %s", identity.ID)
	}

	name, keep, err := v.resolveName(identity, row, hasRow)

	if err != nil {
		return content.ItemDef{}, false, err
	}

	if !keep {
		return content.ItemDef{}, false, nil
	}

	item := content.ItemDef{
		ID:                identity.ID,
		Name:              name.Text,
		Glyph:             glyph,
		Class:             identity.ClassID,
		ClassValue:        identity.ClassValue,
		SubtypeValue:      identity.SubtypeValue,
		Naming:            name,
		ExplicitlyRemoved: identity.ExplicitlyRemoved,
		Evidence: content.ItemEvidence{
			NameSource: name.SourcePath,
			NameLine:   name.SourceLine,
		},
		Armour:  row.Armour,
		Weapon:  row.Weapon,
		Missile: row.Missile,
		Food:    row.Food,
	}

	if hasRow {
		item.Evidence.PropertySource = "crawl-ref/source/item-prop.cc"
		item.Evidence.PropertyLine = row.Line

		if identity.ClassID == "OBJ_FOOD" {
			item.PropertyName = row.Name
		}
	}

	if err := classifyItem(&item, identity, row); err != nil {
		return content.ItemDef{}, false, err
	}

	return item, true, nil
}

func requiresPropertyRow(classID string) bool {
	switch classID {
	case "OBJ_WEAPONS", "OBJ_ARMOUR", "OBJ_MISSILES", "OBJ_FOOD":
		return true
	}

	return false
}

func (v itemSourceViews) resolveName(
	identity content.ItemIdentity,
	row itemPropertyRow,
	hasRow bool,
) (content.ItemName, bool, error) {
	key := itemKey{
		ClassID:   identity.ClassID,
		SubtypeID: identity.ID,
	}

	name, hasName := v.names[key]

	if identity.ClassID != "OBJ_FOOD" && hasRow {
		if hasName && name.Text != row.Name {
			return content.ItemName{}, false, fmt.Errorf("conflicting names for %s", identity.ID)
		}

		name = content.ItemName{
			Text:       row.Name,
			Kind:       "static",
			SourcePath: "crawl-ref/source/item-prop.cc",
			SourceLine: row.Line,
		}

		hasName = true
	}

	if !hasName {
		if identity.ExplicitlyRemoved && !hasRow {
			return content.ItemName{}, false, nil
		}

		return content.ItemName{}, false, fmt.Errorf("missing source name for %s", identity.ID)
	}

	return name, true, nil
}

func classifyItem(item *content.ItemDef, identity content.ItemIdentity, row itemPropertyRow) error {
	switch identity.ClassID {
	case "OBJ_WEAPONS":
		item.Slot = "weapon"
		item.WeaponSkill = row.Weapon.SkillID

	case "OBJ_ARMOUR":
		switch row.Armour.SlotID {
		case "EQ_BODY_ARMOUR":
			item.Slot = "body"

		case "EQ_SHIELD":
			item.Slot = "shield"

		case "EQ_HELMET":
			item.Slot = "head"

		case "EQ_CLOAK":
			item.Slot = "cloak"

		case "EQ_GLOVES":
			item.Slot = "gloves"

		case "EQ_BOOTS":
			item.Slot = "boots"

		default:
			return fmt.Errorf("unsupported armour slot %s for %s", row.Armour.SlotID, identity.ID)
		}

	case "OBJ_MISSILES", "OBJ_POTIONS", "OBJ_SCROLLS", "OBJ_FOOD", "OBJ_GOLD":
		item.Stackable = true
	}

	return nil
}
