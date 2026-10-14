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

type sourceName struct {
	text string
	line int
}

var directCaseName = regexp.MustCompile(`case\s+([A-Z][A-Z0-9_]*)\s*:\s*return\s+"((?:\\.|[^"\\])*)"\s*;`)
var directShowCase = regexp.MustCompile(`case\s+(OBJ_[A-Z0-9_]+)\s*:\s*return\s+(SHOW_ITEM_[A-Z0-9_]+)\s*;`)
var asciiChar = regexp.MustCompile(`(?:U)?'(?:\\.|[^'\\])+'`)

func sourceNameView(path string, data []byte) (sourceView, error) {
	// The needed naming functions precede unrelated tile-only conditionals.
	cut := strings.Index(string(data), "#ifdef USE_TILE_WEB")

	if cut >= 0 {
		data = data[:cut]
	}

	return newSourceView(path, data)
}

func functionBody(view sourceView, marker string) (string, int, error) {
	start := strings.Index(view.text, marker+"(")

	if start < 0 {
		return "", 0, fmt.Errorf("%s: missing %s", view.path, marker)
	}

	open := strings.Index(view.text[start:], "{")

	if open < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks body", view.path, view.line(start), marker)
	}

	open += start
	body, _, err := balancedPart(view.text, open, '{', '}')

	if err != nil {
		return "", 0, fmt.Errorf("%s:%d: %s: %w", view.path, view.line(open), marker, err)
	}

	return body, open + 1, nil
}

func caseNames(view sourceView, body string, offset int) (map[string]sourceName, error) {
	names := map[string]sourceName{}

	for _, match := range directCaseName.FindAllStringSubmatchIndex(body, -1) {
		id := body[match[2]:match[3]]
		value, err := strconv.Unquote(`"` + body[match[4]:match[5]] + `"`)

		if err != nil {
			return nil, fmt.Errorf("%s:%d: invalid name for %s: %w", view.path, view.line(offset+match[0]), id, err)
		}

		if _, found := names[id]; found {
			return nil, fmt.Errorf("%s:%d: ambiguous name for %s", view.path, view.line(offset+match[0]), id)
		}

		names[id] = sourceName{
			text: value,
			line: view.line(offset + match[0]),
		}
	}

	return names, nil
}

func functionCaseNames(view sourceView, marker string) (map[string]sourceName, error) {
	body, offset, err := functionBody(view, marker)

	if err != nil {
		return nil, err
	}

	return caseNames(view, body, offset)
}

func sourceLineFor(view sourceView, text string) (int, error) {
	where := strings.Index(view.text, text)

	if where < 0 {
		return 0, fmt.Errorf("%s: missing naming case %q", view.path, text)
	}

	return view.line(where), nil
}

func parseItemNames(path string, data []byte, identities []content.ItemIdentity) (map[itemKey]content.ItemName, error) {
	view, err := sourceNameView(path, data)

	if err != nil {
		return nil, err
	}

	functions := map[string]string{
		"OBJ_WANDS":      "_wand_type_name",
		"OBJ_POTIONS":    "potion_type_name",
		"OBJ_SCROLLS":    "scroll_type_name",
		"OBJ_JEWELLERY":  "jewellery_effect_name",
		"OBJ_MISCELLANY": "misc_type_name",
		"OBJ_BOOKS":      "_book_type_name",
		"OBJ_STAVES":     "staff_type_name",
		"OBJ_RUNES":      "rune_type_name",
	}
	needed := map[string]bool{}

	for _, identity := range identities {
		needed[identity.ClassID] = true
	}

	functionNames := map[string]map[string]sourceName{}

	for class, marker := range functions {
		if !needed[class] {
			continue
		}

		if class == "OBJ_JEWELLERY" {
			body, offset, err := functionBody(view, marker)

			if err != nil {
				return nil, err
			}

			where := strings.Index(body, "if (!terse)")

			if where < 0 {
				return nil, fmt.Errorf("%s: missing non-terse jewellery names", path)
			}

			open := strings.Index(body[where:], "{") + where
			inner, _, err := balancedPart(body, open, '{', '}')

			if err != nil {
				return nil, fmt.Errorf("%s: malformed jewellery names: %w", path, err)
			}

			functionNames[class], err = caseNames(view, inner, offset+open+1)

			if err != nil {
				return nil, err
			}

			continue
		}

		functionNames[class], err = functionCaseNames(view, marker)

		if err != nil {
			return nil, err
		}
	}

	var subtypeCases map[string]sourceName

	if needed["OBJ_BOOKS"] || needed["OBJ_CORPSES"] || needed["OBJ_ORBS"] || needed["OBJ_GOLD"] {
		subtypeCases, err = functionCaseNames(view, "sub_type_string")

		if err != nil {
			return nil, err
		}
	}

	result := map[itemKey]content.ItemName{}
	add := func(identity content.ItemIdentity, text, kind string, line int) {
		result[itemKey{
			ClassID:   identity.ClassID,
			SubtypeID: identity.ID,
		}] = content.ItemName{
			Text:       text,
			Kind:       kind,
			SourcePath: path,
			SourceLine: line,
		}
	}

	for _, identity := range identities {
		class, id := identity.ClassID, identity.ID

		if class == "OBJ_WEAPONS" || class == "OBJ_ARMOUR" || class == "OBJ_MISSILES" {
			continue // Names for these classes come from their property rows.
		}

		if class == "OBJ_BOOKS" && id == "BOOK_MANUAL" {
			line, err := sourceLineFor(view, "case BOOK_MANUAL:")

			if err != nil {
				return nil, err
			}

			add(identity, "manual", "manual_skill", line)
			continue
		}

		if class == "OBJ_CORPSES" {
			line, err := sourceLineFor(view, "case OBJ_CORPSES:")

			if err != nil {
				return nil, err
			}

			text := "corpse"

			if id == "CORPSE_SKELETON" {
				text = "skeleton"
			}

			add(identity, text, "corpse_monster", line)
			continue
		}

		if class == "OBJ_MISCELLANY" && strings.HasPrefix(id, "MISC_DECK_") {
			line, err := sourceLineFor(view, `return "removed deck"`)

			if err != nil {
				return nil, err
			}

			add(identity, "removed deck", "static", line)
			continue
		}

		if class == "OBJ_GOLD" {
			entry, found := subtypeCases["OBJ_GOLD"]

			if !found {
				return nil, fmt.Errorf("%s: missing gold naming case", path)
			}

			add(identity, "gold piece", "static", entry.line)
			continue
		}

		if class == "OBJ_ORBS" {
			entry, found := subtypeCases["OBJ_ORBS"]

			if !found {
				return nil, fmt.Errorf("%s: missing orb naming case", path)
			}

			add(identity, "Orb of Zot", "static", entry.line)
			continue
		}

		if class == "OBJ_FOOD" || class == "OBJ_RODS" {
			text := "removed food"

			if class == "OBJ_RODS" {
				text = "removed rod"
			}

			line, err := sourceLineFor(view, `return "`+text+`"`)

			if err != nil {
				// The fixed food phrase occurs later than the narrow function view.
				where := strings.Index(string(data), `"`+text+`"`)

				if where < 0 {
					return nil, err
				}

				line = strings.Count(string(data[:where]), "\n") + 1
			}

			add(identity, text, "static", line)
			continue
		}

		entry, found := functionNames[class][id]

		if class == "OBJ_BOOKS" {
			if override, ok := subtypeCases[id]; ok {
				entry, found = override, true
				add(identity, entry.text, "static", entry.line)
				continue
			}

			if found {
				add(identity, "book of "+entry.text, "static", entry.line)
			}

			continue
		}

		if !found {
			if class == "OBJ_POTIONS" && !identity.ExplicitlyRemoved {
				return nil, fmt.Errorf("%s: missing potion name for %s", path, id)
			}

			continue
		}

		switch class {
		case "OBJ_WANDS":
			add(identity, "wand of "+entry.text, "static", entry.line)
		case "OBJ_POTIONS":
			add(identity, "potion of "+entry.text, "static", entry.line)
		case "OBJ_SCROLLS":
			add(identity, "scroll of "+entry.text, "static", entry.line)
		case "OBJ_JEWELLERY":
			prefix := "ring of "

			if strings.HasPrefix(id, "AMU_") {
				prefix = "amulet of "
			}

			add(identity, prefix+entry.text, "static", entry.line)
		case "OBJ_STAVES":
			add(identity, "staff of "+entry.text, "static", entry.line)
		case "OBJ_RUNES":
			add(identity, entry.text+" rune of Zot", "static", entry.line)
		default:
			add(identity, entry.text, "static", entry.line)
		}
	}

	return result, nil
}

func enumBeforeCount(path string, data []byte, name, countID string) ([]enumValue, error) {
	entries, err := enumMembers(path, data, name)

	if err != nil {
		return nil, err
	}

	for i, entry := range entries {
		if entry.ID == countID {
			return entries[:i], nil
		}
	}

	return nil, fmt.Errorf("%s: missing %s", path, countID)
}

func asciiTable(path string, data []byte) ([]rune, error) {
	raw := string(data)
	start := strings.Index(raw, "// CSET_ASCII")

	if start < 0 {
		return nil, fmt.Errorf("%s: missing CSET_ASCII", path)
	}

	section := []byte(raw[start:])
	lines, err := sourceparse.Tag34NumberedLines(path, section)

	if err != nil {
		return nil, err
	}

	var active strings.Builder

	for _, line := range lines {
		active.WriteString(line.Text)
		active.WriteByte('\n')
	}

	text := active.String()
	open := strings.Index(text, "{")

	if open < 0 {
		return nil, fmt.Errorf("%s: missing ASCII table brace", path)
	}

	inside, _, err := balancedPart(text, open, '{', '}')

	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}

	var values []rune

	for _, token := range asciiChar.FindAllString(inside, -1) {
		literal := strings.TrimPrefix(token, "U")
		value, err := strconv.Unquote(literal)

		if err != nil || len([]rune(value)) != 1 {
			return nil, fmt.Errorf("%s: unsupported ASCII glyph %q", path, token)
		}

		values = append(values, []rune(value)[0])
	}

	return values, nil
}

func showClassCodes(path string, data []byte) (map[string]string, error) {
	raw := string(data)
	start := strings.LastIndex(raw, "static show_item_type _item_to_show_code(const item_def &item)")

	if start < 0 {
		return nil, fmt.Errorf("%s: missing item show function", path)
	}

	open := strings.Index(raw[start:], "{")

	if open < 0 {
		return nil, fmt.Errorf("%s: item show function lacks body", path)
	}

	open += start
	body, _, err := balancedPart(raw, open, '{', '}')

	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}

	lines, err := sourceparse.Tag34NumberedLines(path, []byte(body))

	if err != nil {
		return nil, err
	}

	var active strings.Builder

	for _, line := range lines {
		active.WriteString(line.Text)
		active.WriteByte('\n')
	}

	body = active.String()
	codes := map[string]string{}

	for _, match := range directShowCase.FindAllStringSubmatch(body, -1) {
		if _, found := codes[match[1]]; found {
			return nil, fmt.Errorf("%s: duplicate show case %s", path, match[1])
		}

		codes[match[1]] = match[2]
	}

	if !strings.Contains(body, "jewellery_is_amulet(item) ? SHOW_ITEM_AMULET : SHOW_ITEM_RING") ||
		!strings.Contains(body, "item.sub_type == CORPSE_SKELETON") {
		return nil, fmt.Errorf("%s: missing subtype-dependent item show cases", path)
	}

	codes["OBJ_JEWELLERY"] = "SHOW_ITEM_RING"
	codes["OBJ_CORPSES"] = "SHOW_ITEM_CORPSE"

	return codes, nil
}

func parseASCIIItemGlyphs(
	showPath string,
	showData []byte,
	showHeader []byte,
	dcharHeader []byte,
	viewPath string,
	viewData []byte,
	identities []content.ItemIdentity,
) (map[itemKey]rune, error) {
	showEntries, err := enumBeforeCount("crawl-ref/source/show.h", showHeader, "show_item_type", "NUM_SHOW_ITEMS")

	if err != nil {
		return nil, err
	}

	dcharEntries, err := enumBeforeCount(
		"crawl-ref/source/dungeon-char-type.h",
		dcharHeader,
		"dungeon_char_type",
		"NUM_DCHAR_TYPES",
	)

	if err != nil {
		return nil, err
	}

	showItems := []string{}

	for _, entry := range showEntries {
		if entry.ID != "SHOW_ITEM_NONE" {
			showItems = append(showItems, strings.TrimPrefix(entry.ID, "SHOW_ITEM_"))
		}
	}

	dcharItems := []string{}
	dcharIndex := map[string]int{}

	for i, entry := range dcharEntries {
		if strings.HasPrefix(entry.ID, "DCHAR_ITEM_") {
			suffix := strings.TrimPrefix(entry.ID, "DCHAR_ITEM_")
			dcharItems = append(dcharItems, suffix)
			dcharIndex["SHOW_ITEM_"+suffix] = i
		}
	}

	if len(showItems) != len(dcharItems) {
		return nil, fmt.Errorf("show/dchar item counts differ")
	}

	for i := range showItems {
		if showItems[i] != dcharItems[i] {
			return nil, fmt.Errorf("show/dchar item order differs at %d: %s/%s", i, showItems[i], dcharItems[i])
		}
	}

	chars, err := asciiTable(viewPath, viewData)

	if err != nil {
		return nil, err
	}

	if len(chars) != len(dcharEntries) {
		return nil, fmt.Errorf(
			"%s: ASCII glyph count %d differs from dchar count %d",
			viewPath,
			len(chars),
			len(dcharEntries),
		)
	}

	codes, err := showClassCodes(showPath, showData)

	if err != nil {
		return nil, err
	}

	result := map[itemKey]rune{}

	for _, identity := range identities {
		code, found := codes[identity.ClassID]

		if !found {
			return nil, fmt.Errorf("%s: missing show code for %s", showPath, identity.ClassID)
		}

		if identity.ClassID == "OBJ_JEWELLERY" && strings.HasPrefix(identity.ID, "AMU_") {
			code = "SHOW_ITEM_AMULET"
		}

		if identity.ID == "CORPSE_SKELETON" {
			code = "SHOW_ITEM_SKELETON"
		}

		index, found := dcharIndex[code]

		if !found || index >= len(chars) {
			return nil, fmt.Errorf("%s: unknown show glyph reference %s", showPath, code)
		}

		result[itemKey{
			ClassID:   identity.ClassID,
			SubtypeID: identity.ID,
		}] = chars[index]
	}

	return result, nil
}

func sortedItemKeys(names map[itemKey]content.ItemName) []itemKey {
	keys := make([]itemKey, 0, len(names))

	for key := range names {
		keys = append(keys, key)
	}

	sort.Slice(keys, func(i, j int) bool {
		if keys[i].ClassID != keys[j].ClassID {
			return keys[i].ClassID < keys[j].ClassID
		}

		return keys[i].SubtypeID < keys[j].SubtypeID
	})

	return keys
}
