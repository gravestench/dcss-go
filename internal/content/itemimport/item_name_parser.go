package itemimport

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/content"
)

type itemNameParser struct {
	path          string
	data          []byte
	view          sourceView
	functionNames map[string]map[string]sourceName
	subtypeCases  map[string]sourceName
	names         map[itemKey]content.ItemName
}

func parseItemNames(
	path string,
	data []byte,
	identities []content.ItemIdentity,
) (map[itemKey]content.ItemName, error) {
	view, err := sourceNameView(path, data)

	if err != nil {
		return nil, err
	}

	parser := itemNameParser{
		path:          path,
		data:          data,
		view:          view,
		functionNames: map[string]map[string]sourceName{},
		names:         map[itemKey]content.ItemName{},
	}

	needed := map[string]bool{}

	for _, identity := range identities {
		needed[identity.ClassID] = true
	}

	if err := parser.loadFunctionNames(needed); err != nil {
		return nil, err
	}

	if err := parser.loadSubtypeCases(needed); err != nil {
		return nil, err
	}

	for _, identity := range identities {
		if err := parser.addIdentity(identity); err != nil {
			return nil, err
		}
	}

	return parser.names, nil
}

func (parser *itemNameParser) loadFunctionNames(needed map[string]bool) error {
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

	for class, marker := range functions {
		if !needed[class] {
			continue
		}

		var names map[string]sourceName
		var err error

		if class == "OBJ_JEWELLERY" {
			names, err = parser.jewelleryCaseNames(marker)
		} else {
			names, err = functionCaseNames(parser.view, marker)
		}

		if err != nil {
			return err
		}

		parser.functionNames[class] = names
	}

	return nil
}

func (parser *itemNameParser) jewelleryCaseNames(marker string) (map[string]sourceName, error) {
	body, offset, err := functionBody(parser.view, marker)

	if err != nil {
		return nil, err
	}

	where := strings.Index(body, "if (!terse)")

	if where < 0 {
		return nil, fmt.Errorf("%s: missing non-terse jewellery names", parser.path)
	}

	open := strings.Index(body[where:], "{") + where
	inner, _, err := balancedPart(body, open, '{', '}')

	if err != nil {
		return nil, fmt.Errorf("%s: malformed jewellery names: %w", parser.path, err)
	}

	return caseNames(parser.view, inner, offset+open+1)
}

func (parser *itemNameParser) loadSubtypeCases(needed map[string]bool) error {
	if !needed["OBJ_BOOKS"] &&
		!needed["OBJ_CORPSES"] &&
		!needed["OBJ_ORBS"] &&
		!needed["OBJ_GOLD"] {
		return nil
	}

	cases, err := functionCaseNames(parser.view, "sub_type_string")

	if err != nil {
		return err
	}

	parser.subtypeCases = cases

	return nil
}

func (parser *itemNameParser) add(identity content.ItemIdentity, text, kind string, line int) {
	parser.names[itemKey{
		ClassID:   identity.ClassID,
		SubtypeID: identity.ID,
	}] = content.ItemName{
		Text:       text,
		Kind:       kind,
		SourcePath: parser.path,
		SourceLine: line,
	}
}

func (parser *itemNameParser) addIdentity(identity content.ItemIdentity) error {
	class := identity.ClassID

	if class == "OBJ_WEAPONS" || class == "OBJ_ARMOUR" || class == "OBJ_MISSILES" {
		return nil // Names for these classes come from their property rows.
	}

	handled, err := parser.addSpecialIdentity(identity)

	if err != nil || handled {
		return err
	}

	return parser.addOrdinaryIdentity(identity)
}

func (parser *itemNameParser) addSpecialIdentity(identity content.ItemIdentity) (bool, error) {
	class, id := identity.ClassID, identity.ID

	if class == "OBJ_BOOKS" && id == "BOOK_MANUAL" {
		line, err := sourceLineFor(parser.view, "case BOOK_MANUAL:")

		if err != nil {
			return true, err
		}

		parser.add(identity, "manual", "manual_skill", line)

		return true, nil
	}

	if class == "OBJ_CORPSES" {
		line, err := sourceLineFor(parser.view, "case OBJ_CORPSES:")

		if err != nil {
			return true, err
		}

		name := "corpse"

		if id == "CORPSE_SKELETON" {
			name = "skeleton"
		}

		parser.add(identity, name, "corpse_monster", line)

		return true, nil
	}

	if class == "OBJ_MISCELLANY" && strings.HasPrefix(id, "MISC_DECK_") {
		line, err := sourceLineFor(parser.view, `return "removed deck"`)

		if err != nil {
			return true, err
		}

		parser.add(identity, "removed deck", "static", line)

		return true, nil
	}

	if class == "OBJ_GOLD" || class == "OBJ_ORBS" {
		return true, parser.addFixedTreasureName(identity)
	}

	if class == "OBJ_FOOD" || class == "OBJ_RODS" {
		return true, parser.addRemovedItemName(identity)
	}

	return false, nil
}

func (parser *itemNameParser) addFixedTreasureName(identity content.ItemIdentity) error {
	class := identity.ClassID
	entry, found := parser.subtypeCases[class]

	if !found {
		if class == "OBJ_GOLD" {
			return fmt.Errorf("%s: missing gold naming case", parser.path)
		}

		return fmt.Errorf("%s: missing orb naming case", parser.path)
	}

	if class == "OBJ_GOLD" {
		parser.add(identity, "gold piece", "static", entry.line)
	} else {
		parser.add(identity, "Orb of Zot", "static", entry.line)
	}

	return nil
}

func (parser *itemNameParser) addRemovedItemName(identity content.ItemIdentity) error {
	name := "removed food"

	if identity.ClassID == "OBJ_RODS" {
		name = "removed rod"
	}

	line, err := sourceLineFor(parser.view, `return "`+name+`"`)

	if err != nil {
		// The fixed food phrase occurs later than the narrow function view.
		where := strings.Index(string(parser.data), `"`+name+`"`)

		if where < 0 {
			return err
		}

		line = strings.Count(string(parser.data[:where]), "\n") + 1
	}

	parser.add(identity, name, "static", line)

	return nil
}

func (parser *itemNameParser) addOrdinaryIdentity(identity content.ItemIdentity) error {
	class, id := identity.ClassID, identity.ID
	entry, found := parser.functionNames[class][id]

	if class == "OBJ_BOOKS" {
		if override, ok := parser.subtypeCases[id]; ok {
			parser.add(identity, override.text, "static", override.line)

			return nil
		}

		if found {
			parser.add(identity, "book of "+entry.text, "static", entry.line)
		}

		return nil
	}

	if !found {
		if class == "OBJ_POTIONS" && !identity.ExplicitlyRemoved {
			return fmt.Errorf("%s: missing potion name for %s", parser.path, id)
		}

		return nil
	}

	parser.add(identity, ordinaryItemName(class, id, entry.text), "static", entry.line)

	return nil
}

func ordinaryItemName(class, id, name string) string {
	switch class {
	case "OBJ_WANDS":
		return "wand of " + name

	case "OBJ_POTIONS":
		return "potion of " + name

	case "OBJ_SCROLLS":
		return "scroll of " + name

	case "OBJ_JEWELLERY":
		if strings.HasPrefix(id, "AMU_") {
			return "amulet of " + name
		}

		return "ring of " + name

	case "OBJ_STAVES":
		return "staff of " + name

	case "OBJ_RUNES":
		return name + " rune of Zot"

	default:
		return name
	}
}
