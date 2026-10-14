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
	{
		ClassID: "OBJ_WEAPONS",
		File:    "item-prop-enum.h",
		Enum:    "weapon_type",
		Prefix:  []string{"WPN_"},
		End:     "NUM_WEAPONS",
	},
	{
		ClassID: "OBJ_MISSILES",
		File:    "item-prop-enum.h",
		Enum:    "missile_type",
		Prefix:  []string{"MI_"},
		End:     "NUM_MISSILES",
	},
	{
		ClassID: "OBJ_ARMOUR",
		File:    "item-prop-enum.h",
		Enum:    "armour_type",
		Prefix:  []string{"ARM_"},
		End:     "NUM_ARMOURS",
	},
	{
		ClassID: "OBJ_WANDS",
		File:    "item-prop-enum.h",
		Enum:    "wand_type",
		Prefix:  []string{"WAND_"},
		End:     "NUM_WANDS",
	},
	{
		ClassID: "OBJ_FOOD",
		File:    "item-prop-enum.h",
		Enum:    "food_type",
		Prefix:  []string{"FOOD_"},
		End:     "NUM_FOODS",
	},
	{
		ClassID: "OBJ_SCROLLS",
		File:    "item-prop-enum.h",
		Enum:    "scroll_type",
		Prefix:  []string{"SCR_"},
		End:     "NUM_SCROLLS",
	},
	{
		ClassID: "OBJ_JEWELLERY",
		File:    "item-prop-enum.h",
		Enum:    "jewellery_type",
		Prefix:  []string{"RING_", "AMU_"},
		End:     "NUM_JEWELLERY",
	},
	{
		ClassID: "OBJ_POTIONS",
		File:    "potion-type.h",
		Enum:    "potion_type",
		Prefix:  []string{"POT_"},
		End:     "NUM_POTIONS",
	},
	{
		ClassID: "OBJ_BOOKS",
		File:    "book-type.h",
		Enum:    "book_type",
		Prefix:  []string{"BOOK_"},
		End:     "NUM_BOOKS",
	},
	{
		ClassID: "OBJ_STAVES",
		File:    "item-prop-enum.h",
		Enum:    "stave_type",
		Prefix:  []string{"STAFF_"},
		End:     "NUM_STAVES",
	},
	{
		ClassID: "OBJ_ORBS",
		File:    "orb-type.h",
		Enum:    "orb_type",
		Prefix:  []string{"ORB_"},
		End:     "",
	},
	{
		ClassID: "OBJ_MISCELLANY",
		File:    "item-prop-enum.h",
		Enum:    "misc_item_type",
		Prefix:  []string{"MISC_"},
		End:     "NUM_MISCELLANY",
	},
	{
		ClassID: "OBJ_CORPSES",
		File:    "item-prop-enum.h",
		Enum:    "corpse_type",
		Prefix:  []string{"CORPSE_"},
		End:     "",
	},
	{
		ClassID: "OBJ_RODS",
		File:    "item-prop-enum.h",
		Enum:    "rod_type",
		Prefix:  []string{"ROD_"},
		End:     "NUM_RODS",
	},
	{
		ClassID: "OBJ_RUNES",
		File:    "item-prop-enum.h",
		Enum:    "rune_type",
		Prefix:  []string{"RUNE_"},
		End:     "NUM_RUNE_TYPES",
	},
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
			entries = append(entries, enumValue{
				ID:         id,
				Value:      value,
				AliasOf:    alias,
				SourcePath: path,
				SourceLine: line.Number,
			})
		}
	}

	if state != 3 || len(entries) == 0 {
		return nil, fmt.Errorf("%s: missing or empty enum %s", path, name)
	}

	return entries, nil
}

func parseIdentities(source map[string][]byte) ([]content.ItemIdentity, []content.ItemAlias, error) {
	classEntries, err := enumMembers(
		"crawl-ref/source/object-class-type.h",
		source["object-class-type.h"],
		"object_class_type",
	)

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
			return fmt.Errorf(
				"%s:%d: subtype %s duplicates numeric pair of %s",
				entry.SourcePath,
				entry.SourceLine,
				entry.ID,
				previous,
			)
		}

		seenPairs[pair] = entry.ID
		identities = append(identities, content.ItemIdentity{
			ID:           entry.ID,
			ClassID:      classID,
			ClassValue:   classValue,
			SubtypeValue: entry.Value,
			SourcePath:   entry.SourcePath,
			SourceLine:   entry.SourceLine,
		})

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
					aliases = append(aliases, content.ItemAlias{
						ID:           entry.ID,
						TargetID:     entry.AliasOf,
						ClassID:      class.ClassID,
						NumericValue: entry.Value,
						SourcePath:   entry.SourcePath,
						SourceLine:   entry.SourceLine,
					})
				}

				continue
			}

			if !matchesPrefix || strings.HasPrefix(entry.ID, "NUM_") ||
				strings.HasPrefix(entry.ID, "MAX_") || strings.Contains(entry.ID, "_FIRST_") ||
				strings.Contains(entry.ID, "_LAST_") || strings.HasSuffix(entry.ID, "_UNKNOWN") {
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

	gold := enumValue{
		ID:         "OBJ_GOLD",
		Value:      0,
		SourcePath: "crawl-ref/source/object-class-type.h",
	}

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
	sort.Slice(aliases, func(i, j int) bool {
		return aliases[i].ID < aliases[j].ID
	})

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

		key := itemKey{
			ClassID:   match[1],
			SubtypeID: match[2],
		}

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
		{
			place:    &v.Slots,
			file:     "equipment-type.h",
			enum:     "equipment_type",
			prefixes: []string{"EQ_"},
		},
		{
			place:    &v.Skills,
			file:     "skill-type.h",
			enum:     "skill_type",
			prefixes: []string{"SK_"},
		},
		{
			place:    &v.Sizes,
			file:     "size-type.h",
			enum:     "size_type",
			prefixes: []string{"SIZE_", "NUM_SIZE_LEVELS"},
		},
		{
			place:    &v.Ammo,
			file:     "item-prop-enum.h",
			enum:     "missile_type",
			prefixes: []string{"MI_"},
		},
		{
			place: &v.DamageFlags,
			file:  "item-prop-enum.h",
			enum:  "vorpal_damage_type",
			prefixes: []string{
				"DAM_",
				"DAMV_",
				"DVORP_",
			},
		},
		{
			place:    &v.Brands,
			file:     "item-prop-enum.h",
			enum:     "brand_type",
			prefixes: []string{"SPWPN_"},
		},
		{
			place:    &v.ArmourFlags,
			file:     "item-prop.h",
			enum:     "armour_flag",
			prefixes: []string{"ARMF_"},
		},
	} {
		ids, err := enumSymbolIDs("crawl-ref/source/"+spec.file, source[spec.file], spec.enum, spec.prefixes...)

		if err != nil {
			return v, err
		}

		*spec.place = ids
	}

	return v, nil
}
