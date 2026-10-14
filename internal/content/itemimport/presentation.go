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

var directShowCase = regexp.MustCompile(
	`case\s+(OBJ_[A-Z0-9_]+)\s*:\s*return\s+(SHOW_ITEM_[A-Z0-9_]+)\s*;`,
)

var asciiChar = regexp.MustCompile(`(?:U)?'(?:\\.|[^'\\])+'`)

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

		if err != nil ||
			len([]rune(value)) != 1 {
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

	const jewelleryShowCase = "jewellery_is_amulet(item) ? SHOW_ITEM_AMULET : SHOW_ITEM_RING"

	if !strings.Contains(body, jewelleryShowCase) ||
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
	showEntries, err := enumBeforeCount(
		"crawl-ref/source/show.h",
		showHeader,
		"show_item_type",
		"NUM_SHOW_ITEMS",
	)

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
			return nil, fmt.Errorf(
				"show/dchar item order differs at %d: %s/%s",
				i,
				showItems[i],
				dcharItems[i],
			)
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

		if identity.ClassID == "OBJ_JEWELLERY" &&
			strings.HasPrefix(identity.ID, "AMU_") {
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
