package startinggearimport

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var (
	enumIDPattern   = regexp.MustCompile(`^([A-Z][A-Z0-9_]*)(\s*=\s*[^,]+)?\s*,?`)
	armourRow       = regexp.MustCompile(`(?s)\{\s*(ARM_[A-Z0-9_]+),\s*"([^"]+)"[^{}]*?\b(EQ_[A-Z0-9_]+)`)
	weaponRow       = regexp.MustCompile(`(?s)\{\s*(WPN_[A-Z0-9_]+),\s*"([^"]+)"[^{}]*?\b(SK_[A-Z0-9_]+)`)
	missileRow      = regexp.MustCompile(`\{\s*(MI_[A-Z0-9_]+),\s*"([^"]+)"`)
	indirectNameRow = regexp.MustCompile(`case\s+((?:POT|SCR|WAND|MISC)_[A-Z0-9_]+):\s*return\s+"([^"]+)"`)
)

func readKindSource(root, name string) ([]byte, string, error) {
	path := filepath.Join(root, name)
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, path, fmt.Errorf("%s: %w", path, err)
	}
	return data, path, nil
}

// item-prop-enum.h has several enums; ActiveEnumIDs handles one at a time.
func activeItemIDs(path string, data []byte) (map[string]bool, error) {
	lines, err := sourceparse.Tag34Lines(path, data)
	if err != nil {
		return nil, err
	}
	ids := map[string]bool{}
	inside, waiting := false, false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "enum ") {
			waiting = true
			inside = strings.Contains(trimmed, "{")
			continue
		}
		if waiting && !inside && strings.Contains(trimmed, "{") {
			inside = true
			continue
		}
		if inside && strings.HasPrefix(trimmed, "}") {
			inside, waiting = false, false
			continue
		}
		if !inside {
			continue
		}
		match := enumIDPattern.FindStringSubmatch(trimmed)
		if match == nil || match[2] != "" {
			continue
		}
		id := match[1]
		if !(strings.HasPrefix(id, "ARM_") || strings.HasPrefix(id, "WPN_") || strings.HasPrefix(id, "MI_") || strings.HasPrefix(id, "SCR_") || strings.HasPrefix(id, "WAND_") || strings.HasPrefix(id, "MISC_") || strings.HasPrefix(id, "SPMSL_")) {
			continue
		}
		if ids[id] {
			return nil, fmt.Errorf("%s: duplicate active item enum %s", path, id)
		}
		ids[id] = true
	}
	if len(ids) == 0 {
		return nil, fmt.Errorf("%s: no active item enum IDs", path)
	}
	return ids, nil
}

func activeSection(path string, data []byte, start, end string) (string, error) {
	begin := strings.Index(string(data), start)
	if begin < 0 {
		return "", fmt.Errorf("%s: missing %s", path, start)
	}
	portion := string(data)[begin:]
	stop := strings.Index(portion, end)
	if stop < 0 {
		return "", fmt.Errorf("%s: unterminated %s", path, start)
	}
	lines, err := sourceparse.Tag34Lines(path, []byte(portion[:stop]))
	if err != nil {
		return "", err
	}
	return strings.Join(lines, "\n"), nil
}

func armourSlot(path, id, cpp string) (string, error) {
	slots := map[string]string{"EQ_BODY_ARMOUR": "body", "EQ_SHIELD": "shield", "EQ_HELMET": "head", "EQ_CLOAK": "cloak", "EQ_GLOVES": "gloves", "EQ_BOOTS": "boots"}
	slot := slots[cpp]
	if slot == "" {
		return "", fmt.Errorf("%s: %s has unsupported armour slot %s", path, id, cpp)
	}
	return slot, nil
}

func resolveKinds(sourceDir string, names []string) ([]content.ItemDef, error) {
	enumData, enumPath, err := readKindSource(sourceDir, "item-prop-enum.h")
	if err != nil {
		return nil, err
	}
	active, err := activeItemIDs(enumPath, enumData)
	if err != nil {
		return nil, err
	}
	potionData, potionPath, err := readKindSource(sourceDir, "potion-type.h")
	if err != nil {
		return nil, err
	}
	potions, err := sourceparse.ActiveEnumIDs(potionPath, potionData, "POT_")
	if err != nil {
		return nil, err
	}
	for id := range potions {
		active[id] = true
	}
	propData, propPath, err := readKindSource(sourceDir, "item-prop.cc")
	if err != nil {
		return nil, err
	}
	nameData, namePath, err := readKindSource(sourceDir, "item-name.cc")
	if err != nil {
		return nil, err
	}
	requested := map[string]bool{}
	for _, name := range names {
		requested[name] = true
	}
	byName := map[string]content.ItemDef{}
	add := func(path string, kind content.ItemDef) error {
		if !requested[kind.Name] {
			return nil
		}
		if !active[kind.ID] {
			return fmt.Errorf("%s: item %s (%s) is not an active tag-34 enum in %s or %s", path, kind.Name, kind.ID, enumPath, potionPath)
		}
		if old, exists := byName[kind.Name]; exists {
			return fmt.Errorf("%s: ambiguous item name %q for %s and %s", path, kind.Name, old.ID, kind.ID)
		}
		byName[kind.Name] = kind
		return nil
	}
	armour, err := activeSection(propPath, propData, "Armour_prop[]", "\n};")
	if err != nil {
		return nil, err
	}
	for _, match := range armourRow.FindAllStringSubmatch(armour, -1) {
		slot, err := armourSlot(propPath, match[1], match[3])
		if err != nil {
			return nil, err
		}
		if err := add(propPath, content.ItemDef{ID: match[1], Name: match[2], Glyph: '[', Class: "OBJ_ARMOUR", Slot: slot}); err != nil {
			return nil, err
		}
	}
	weapons, err := activeSection(propPath, propData, "Weapon_prop[]", "\n};")
	if err != nil {
		return nil, err
	}
	for _, match := range weaponRow.FindAllStringSubmatch(weapons, -1) {
		if err := add(propPath, content.ItemDef{ID: match[1], Name: match[2], Glyph: ')', Class: "OBJ_WEAPONS", Slot: "weapon", WeaponSkill: match[3]}); err != nil {
			return nil, err
		}
	}
	missiles, err := activeSection(propPath, propData, "Missile_prop[]", "\n};")
	if err != nil {
		return nil, err
	}
	for _, match := range missileRow.FindAllStringSubmatch(missiles, -1) {
		if err := add(propPath, content.ItemDef{ID: match[1], Name: match[2], Glyph: '(', Class: "OBJ_MISSILES", Stackable: true}); err != nil {
			return nil, err
		}
	}
	// These four switch functions contain the canonical subtype names. Their
	// object-class prefixes come from item-name.cc's item naming switch.
	indirect, err := activeSection(namePath, nameData, "_wand_type_name", "static const char* _book_type_name")
	if err != nil {
		return nil, err
	}
	for _, match := range indirectNameRow.FindAllStringSubmatch(indirect, -1) {
		id, suffix := match[1], match[2]
		kind := content.ItemDef{ID: id}
		switch {
		case strings.HasPrefix(id, "POT_"):
			kind.Name, kind.Class, kind.Glyph, kind.Stackable = "potion of "+suffix, "OBJ_POTIONS", '!', true
		case strings.HasPrefix(id, "SCR_"):
			kind.Name, kind.Class, kind.Glyph, kind.Stackable = "scroll of "+suffix, "OBJ_SCROLLS", '?', true
		case strings.HasPrefix(id, "WAND_"):
			kind.Name, kind.Class, kind.Glyph = "wand of "+suffix, "OBJ_WANDS", '/'
		case strings.HasPrefix(id, "MISC_"):
			kind.Name, kind.Class, kind.Glyph = suffix, "OBJ_MISCELLANY", '}'
		}
		if err := add(namePath, kind); err != nil {
			return nil, err
		}
	}
	seen := map[string]bool{}
	var result []content.ItemDef
	for _, name := range names {
		if seen[name] {
			continue
		}
		seen[name] = true
		kind, found := byName[name]
		if !found {
			return nil, fmt.Errorf("%s / %s: unknown item name %q", propPath, namePath, name)
		}
		result = append(result, kind)
	}
	sort.Slice(result, func(i, j int) bool { return result[i].ID < result[j].ID })
	return result, nil
}
