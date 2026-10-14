package itemimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

type itemKey struct {
	ClassID   string
	SubtypeID string
}

type enumValue struct {
	ID         string
	Value      int
	AliasOf    string
	SourcePath string
	SourceLine int
}

type classSource struct {
	ClassID string
	File    string
	Enum    string
	Prefix  []string
	End     string
}

var itemClassSources = []classSource{
	{"OBJ_WEAPONS", "item-prop-enum.h", "weapon_type", []string{"WPN_"}, "NUM_WEAPONS"},
	{"OBJ_MISSILES", "item-prop-enum.h", "missile_type", []string{"MI_"}, "NUM_MISSILES"},
	{"OBJ_ARMOUR", "item-prop-enum.h", "armour_type", []string{"ARM_"}, "NUM_ARMOURS"},
	{"OBJ_WANDS", "item-prop-enum.h", "wand_type", []string{"WAND_"}, "NUM_WANDS"},
	{"OBJ_FOOD", "item-prop-enum.h", "food_type", []string{"FOOD_"}, "NUM_FOODS"},
	{"OBJ_SCROLLS", "item-prop-enum.h", "scroll_type", []string{"SCR_"}, "NUM_SCROLLS"},
	{"OBJ_JEWELLERY", "item-prop-enum.h", "jewellery_type", []string{"RING_", "AMU_"}, "NUM_JEWELLERY"},
	{"OBJ_POTIONS", "potion-type.h", "potion_type", []string{"POT_"}, "NUM_POTIONS"},
	{"OBJ_BOOKS", "book-type.h", "book_type", []string{"BOOK_"}, "NUM_BOOKS"},
	{"OBJ_STAVES", "item-prop-enum.h", "stave_type", []string{"STAFF_"}, "NUM_STAVES"},
	{"OBJ_ORBS", "orb-type.h", "orb_type", []string{"ORB_"}, ""},
	{"OBJ_MISCELLANY", "item-prop-enum.h", "misc_item_type", []string{"MISC_"}, "NUM_MISCELLANY"},
	{"OBJ_CORPSES", "item-prop-enum.h", "corpse_type", []string{"CORPSE_"}, ""},
	{"OBJ_RODS", "item-prop-enum.h", "rod_type", []string{"ROD_"}, "NUM_RODS"},
	{"OBJ_RUNES", "item-prop-enum.h", "rune_type", []string{"RUNE_"}, "NUM_RUNE_TYPES"},
}

var enumMemberPattern = regexp.MustCompile(`^([A-Z][A-Z0-9_]*)\s*(?:=\s*(.*))?$`)
var enumHeaderPattern = regexp.MustCompile(`^enum(?:\s+class)?\s+([A-Za-z][A-Za-z0-9_]*)\b`)
var enumSymbolPattern = regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)

// enumMembers reads only one named enum, keeping C++ numeric progression.
func enumMembers(path string, data []byte, name string) ([]enumValue, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)
	if err != nil {
		return nil, err
	}
	state := 0 // before header, before brace, inside enum, finished
	value := -1
	known := map[string]int{}
	var entries []enumValue
	for _, line := range lines {
		trimmed := strings.TrimSpace(line.Text)
		if state == 0 {
			match := enumHeaderPattern.FindStringSubmatch(trimmed)
			if match == nil || match[1] != name {
				continue
			}
			state = 1
			if strings.Contains(trimmed, "{") {
				state = 2
			}
			continue
		}
		if state == 1 {
			if trimmed == "{" {
				state = 2
				continue
			}
			return nil, fmt.Errorf("%s:%d: enum %s lacks opening brace", path, line.Number, name)
		}
		if strings.HasPrefix(trimmed, "}") {
			state = 3
			break
		}
		if trimmed == "" {
			continue
		}
		if strings.ContainsAny(trimmed, "{}") {
			return nil, fmt.Errorf("%s:%d: unsupported enum %s row %q", path, line.Number, name, trimmed)
		}
		for _, raw := range strings.Split(trimmed, ",") {
			part := strings.TrimSpace(raw)
			if part == "" {
				continue
			}
			match := enumMemberPattern.FindStringSubmatch(part)
			if match == nil {
				return nil, fmt.Errorf("%s:%d: unsupported enum %s row %q", path, line.Number, name, part)
			}
			id, expression := match[1], strings.TrimSpace(match[2])
			if _, found := known[id]; found {
				return nil, fmt.Errorf("%s:%d: duplicate enum member %s", path, line.Number, id)
			}
			alias := ""
			if expression == "" {
				value++
			} else if number, err := strconv.ParseInt(expression, 0, 32); err == nil {
				value = int(number)
			} else if enumSymbolPattern.MatchString(expression) {
				referenced, found := known[expression]
				if !found {
					return nil, fmt.Errorf("%s:%d: enum %s references unknown %s", path, line.Number, id, expression)
				}
				value, alias = referenced, expression
			} else {
				return nil, fmt.Errorf("%s:%d: unsupported numeric expression %q for %s", path, line.Number, expression, id)
			}
			known[id] = value
			entries = append(entries, enumValue{ID: id, Value: value, AliasOf: alias, SourcePath: path, SourceLine: line.Number})
		}
	}
	if state != 3 || len(entries) == 0 {
		return nil, fmt.Errorf("%s: missing or empty enum %s", path, name)
	}
	return entries, nil
}

func parseIdentities(source map[string][]byte) ([]content.ItemIdentity, []content.ItemAlias, error) {
	classEntries, err := enumMembers("crawl-ref/source/object-class-type.h", source["object-class-type.h"], "object_class_type")
	if err != nil {
		return nil, nil, err
	}
	classValues := map[string]int{}
	for _, entry := range classEntries {
		if entry.ID == "NUM_OBJECT_CLASSES" {
			break
		}
		if !strings.HasPrefix(entry.ID, "OBJ_") || entry.AliasOf != "" {
			return nil, nil, fmt.Errorf("%s:%d: invalid active class %s", entry.SourcePath, entry.SourceLine, entry.ID)
		}
		classValues[entry.ID] = entry.Value
	}
	if len(classValues) != 16 {
		return nil, nil, fmt.Errorf("object-class-type.h: expected 16 active classes, got %d", len(classValues))
	}
	var identities []content.ItemIdentity
	var aliases []content.ItemAlias
	seenPairs := map[[2]int]string{}
	appendIdentity := func(classID string, classValue int, entry enumValue) error {
		if entry.Value < 0 {
			return fmt.Errorf("%s:%d: negative concrete subtype %s", entry.SourcePath, entry.SourceLine, entry.ID)
		}
		pair := [2]int{classValue, entry.Value}
		if previous, found := seenPairs[pair]; found {
			return fmt.Errorf("%s:%d: subtype %s duplicates numeric pair of %s", entry.SourcePath, entry.SourceLine, entry.ID, previous)
		}
		seenPairs[pair] = entry.ID
		identities = append(identities, content.ItemIdentity{ID: entry.ID, ClassID: classID, ClassValue: classValue, SubtypeValue: entry.Value, SourcePath: entry.SourcePath, SourceLine: entry.SourceLine})
		return nil
	}
	for _, class := range itemClassSources {
		classValue, found := classValues[class.ClassID]
		if !found {
			return nil, nil, fmt.Errorf("missing active item class %s", class.ClassID)
		}
		entries, err := enumMembers("crawl-ref/source/"+class.File, source[class.File], class.Enum)
		if err != nil {
			return nil, nil, err
		}
		concrete := map[string]bool{}
		ended := class.End == ""
		for _, entry := range entries {
			if entry.ID == class.End {
				ended = true
				break
			}
			matchesPrefix := false
			for _, prefix := range class.Prefix {
				matchesPrefix = matchesPrefix || strings.HasPrefix(entry.ID, prefix)
			}
			if entry.AliasOf != "" {
				if concrete[entry.AliasOf] {
					aliases = append(aliases, content.ItemAlias{ID: entry.ID, TargetID: entry.AliasOf, ClassID: class.ClassID, NumericValue: entry.Value, SourcePath: entry.SourcePath, SourceLine: entry.SourceLine})
				}
				continue
			}
			if !matchesPrefix || strings.HasPrefix(entry.ID, "NUM_") || strings.HasPrefix(entry.ID, "MAX_") || strings.Contains(entry.ID, "_FIRST_") || strings.Contains(entry.ID, "_LAST_") || strings.HasSuffix(entry.ID, "_UNKNOWN") {
				continue
			}
			if err := appendIdentity(class.ClassID, classValue, entry); err != nil {
				return nil, nil, err
			}
			concrete[entry.ID] = true
		}
		if !ended || len(concrete) == 0 {
			return nil, nil, fmt.Errorf("%s: incomplete enum %s for %s", class.File, class.Enum, class.ClassID)
		}
	}
	gold := enumValue{ID: "OBJ_GOLD", Value: 0, SourcePath: "crawl-ref/source/object-class-type.h"}
	for _, entry := range classEntries {
		if entry.ID == "OBJ_GOLD" {
			gold.SourceLine = entry.SourceLine
			break
		}
	}
	if err := appendIdentity("OBJ_GOLD", classValues["OBJ_GOLD"], gold); err != nil {
		return nil, nil, err
	}
	sort.Slice(identities, func(i, j int) bool {
		if identities[i].ClassValue != identities[j].ClassValue {
			return identities[i].ClassValue < identities[j].ClassValue
		}
		return identities[i].SubtypeValue < identities[j].SubtypeValue
	})
	sort.Slice(aliases, func(i, j int) bool { return aliases[i].ID < aliases[j].ID })
	return identities, aliases, nil
}

var removedRow = regexp.MustCompile(`^\{\s*(OBJ_[A-Z0-9_]+)\s*,\s*([A-Z][A-Z0-9_]+)\s*\}\s*,?$`)

func parseRemovedItems(path string, data []byte) (map[itemKey]bool, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)
	if err != nil {
		return nil, err
	}
	state := 0
	removed := map[itemKey]bool{}
	for _, line := range lines {
		trimmed := strings.TrimSpace(line.Text)
		if state == 0 {
			if strings.Contains(trimmed, " removed_items ") && strings.HasSuffix(trimmed, "=") {
				state = 1
			}
			continue
		}
		if state == 1 {
			if trimmed != "{" {
				return nil, fmt.Errorf("%s:%d: removed_items lacks opening brace", path, line.Number)
			}
			state = 2
			continue
		}
		if trimmed == "};" {
			state = 3
			break
		}
		if trimmed == "" {
			continue
		}
		match := removedRow.FindStringSubmatch(trimmed)
		if match == nil {
			return nil, fmt.Errorf("%s:%d: unsupported removed_items row %q", path, line.Number, trimmed)
		}
		key := itemKey{ClassID: match[1], SubtypeID: match[2]}
		if removed[key] {
			return nil, fmt.Errorf("%s:%d: duplicate removed item %s/%s", path, line.Number, key.ClassID, key.SubtypeID)
		}
		removed[key] = true
	}
	if state != 3 {
		return nil, fmt.Errorf("%s: missing or unterminated removed_items", path)
	}
	return removed, nil
}

func enumSymbolIDs(path string, data []byte, name string, prefixes ...string) ([]string, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)
	if err != nil {
		return nil, err
	}
	state := 0
	var ids []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line.Text)
		if state == 0 {
			match := enumHeaderPattern.FindStringSubmatch(trimmed)
			if match != nil && match[1] == name {
				state = 1
			}
			continue
		}
		if state == 1 {
			if trimmed != "{" {
				return nil, fmt.Errorf("%s:%d: enum %s lacks opening brace", path, line.Number, name)
			}
			state = 2
			continue
		}
		if strings.HasPrefix(trimmed, "}") {
			state = 3
			break
		}
		if trimmed == "" {
			continue
		}
		member := strings.TrimSpace(strings.TrimSuffix(trimmed, ","))
		parts := strings.SplitN(member, "=", 2)
		id := strings.TrimSpace(parts[0])
		if !enumSymbolPattern.MatchString(id) || (len(parts) == 2 && strings.TrimSpace(parts[1]) == "") {
			return nil, fmt.Errorf("%s:%d: unsupported vocabulary enum row %q", path, line.Number, trimmed)
		}
		for _, prefix := range prefixes {
			if strings.HasPrefix(id, prefix) {
				ids = append(ids, id)
				break
			}
		}
	}
	if state != 3 || len(ids) == 0 {
		return nil, fmt.Errorf("%s: missing or empty vocabulary enum %s", path, name)
	}
	sort.Strings(ids)
	return ids, nil
}

func parseVocabulary(source map[string][]byte) (content.ItemVocabulary, error) {
	var v content.ItemVocabulary
	type target struct {
		place    *[]string
		file     string
		enum     string
		prefixes []string
	}
	for _, spec := range []target{
		{&v.Slots, "equipment-type.h", "equipment_type", []string{"EQ_"}},
		{&v.Skills, "skill-type.h", "skill_type", []string{"SK_"}},
		{&v.Sizes, "size-type.h", "size_type", []string{"SIZE_"}},
		{&v.Ammo, "item-prop-enum.h", "missile_type", []string{"MI_"}},
		{&v.DamageFlags, "item-prop-enum.h", "vorpal_damage_type", []string{"DAM_", "DAMV_", "DVORP_"}},
		{&v.Brands, "item-prop-enum.h", "brand_type", []string{"SPWPN_"}},
		{&v.ArmourFlags, "item-prop.h", "armour_flag", []string{"ARMF_"}},
	} {
		ids, err := enumSymbolIDs("crawl-ref/source/"+spec.file, source[spec.file], spec.enum, spec.prefixes...)
		if err != nil {
			return v, err
		}
		*spec.place = ids
	}
	return v, nil
}
