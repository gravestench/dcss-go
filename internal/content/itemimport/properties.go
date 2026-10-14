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

type itemPropertyRow struct {
	Name    string
	Line    int
	Armour  *content.ArmourProperties
	Weapon  *content.WeaponProperties
	Missile *content.MissileProperties
	Food    *content.FoodProperties
}

type sourceView struct {
	path   string
	text   string
	starts []int
	lines  []int
}

func newSourceView(path string, data []byte) (sourceView, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)

	if err != nil {
		return sourceView{}, err
	}

	v := sourceView{path: path}
	var text strings.Builder

	for _, line := range lines {
		v.starts = append(v.starts, text.Len())
		v.lines = append(v.lines, line.Number)
		text.WriteString(line.Text)
		text.WriteByte('\n')
	}

	v.text = text.String()

	return v, nil
}

func (v sourceView) line(offset int) int {
	index := sort.Search(len(v.starts), func(i int) bool {
		return v.starts[i] > offset
	}) - 1

	if index < 0 {
		return 0
	}

	return v.lines[index]
}

func (v sourceView) initializer(marker string) (string, int, error) {
	start := strings.Index(v.text, marker)

	if start < 0 {
		return "", 0, fmt.Errorf("%s: missing %s", v.path, marker)
	}

	assign := strings.Index(v.text[start+len(marker):], "=")

	if assign < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks initializer", v.path, v.line(start), marker)
	}

	assign += start + len(marker)
	open := strings.Index(v.text[assign:], "{")

	if open < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks opening brace", v.path, v.line(start), marker)
	}

	open += assign
	inside, _, err := balancedPart(v.text, open, '{', '}')

	if err != nil {
		return "", 0, fmt.Errorf("%s:%d: %s: %w", v.path, v.line(open), marker, err)
	}

	return inside, open + 1, nil
}

// balancedPart and splitTopLevel preserve punctuation inside quoted strings.
func balancedPart(text string, start int, open, close byte) (string, int, error) {
	if start >= len(text) || text[start] != open {
		return "", 0, fmt.Errorf("expected %q", open)
	}

	depth := 0
	quote, escape := byte(0), false

	for i := start; i < len(text); i++ {
		c := text[i]

		if quote != 0 {
			if escape {
				escape = false
			} else if c == '\\' {
				escape = true
			} else if c == quote {
				quote = 0
			}

			continue
		}

		if c == '"' || c == '\'' {
			quote = c
			continue
		}

		if c == open {
			depth++
		} else if c == close {
			depth--

			if depth == 0 {
				return text[start+1 : i], i + 1, nil
			}
		}
	}

	return "", 0, fmt.Errorf("unterminated %q block", open)
}

type sourcePart struct {
	text  string
	start int
}

func splitTopLevel(text string, sep byte) ([]sourcePart, error) {
	start, braces, parens := 0, 0, 0
	quote, escape := byte(0), false
	var parts []sourcePart
	appendPart := func(end int) {
		part := text[start:end]
		trimmed := strings.TrimSpace(part)

		if trimmed != "" {
			parts = append(parts, sourcePart{
				text:  trimmed,
				start: start + strings.Index(part, trimmed),
			})
		}
	}

	for i := 0; i < len(text); i++ {
		c := text[i]

		if quote != 0 {
			if escape {
				escape = false
			} else if c == '\\' {
				escape = true
			} else if c == quote {
				quote = 0
			}

			continue
		}

		switch c {
		case '"', '\'':
			quote = c
		case '{':
			braces++
		case '}':
			braces--
		case '(':
			parens++
		case ')':
			parens--
		default:
			if c == sep && braces == 0 && parens == 0 {
				appendPart(i)
				start = i + 1
			}
		}

		if braces < 0 || parens < 0 {
			return nil, fmt.Errorf("unbalanced source row")
		}
	}

	if quote != 0 || braces != 0 || parens != 0 {
		return nil, fmt.Errorf("unterminated source row")
	}

	appendPart(len(text))

	return parts, nil
}

func rowFields(raw string) ([]string, error) {
	if !strings.HasPrefix(raw, "{") {
		return nil, fmt.Errorf("expected braced row")
	}

	inside, end, err := balancedPart(raw, 0, '{', '}')

	if err != nil || strings.TrimSpace(raw[end:]) != "" {
		return nil, fmt.Errorf("malformed braced row")
	}

	parts, err := splitTopLevel(inside, ',')

	if err != nil {
		return nil, err
	}

	fields := make([]string, len(parts))

	for i, part := range parts {
		fields[i] = part.text
	}

	return fields, nil
}

func propertyInt(raw string) (int, error) {
	value, err := strconv.ParseInt(strings.TrimSpace(raw), 0, 32)

	if err != nil {
		return 0, fmt.Errorf("unsupported integer %q", raw)
	}

	return int(value), nil
}

func propertyName(raw string) (string, error) {
	name, err := strconv.Unquote(strings.TrimSpace(raw))

	if err != nil {
		return "", fmt.Errorf("unsupported item name %q", raw)
	}

	return name, nil
}

func knownSymbol(symbol string, list []string) bool {
	return sort.SearchStrings(list, symbol) < len(list) && list[sort.SearchStrings(list, symbol)] == symbol
}

func parseArmourFlags(raw string, vocabulary content.ItemVocabulary) ([]content.ItemFlag, error) {
	if raw == "ARMF_NO_FLAGS" {
		return nil, nil
	}

	parts, err := splitTopLevel(raw, '|')

	if err != nil {
		return nil, err
	}

	var flags []content.ItemFlag

	for _, part := range parts {
		text := part.text
		flag := content.ItemFlag{
			ID:    text,
			Level: 1,
		}

		if strings.HasPrefix(text, "ard(") {
			inside, end, err := balancedPart(text, 3, '(', ')')

			if err != nil || end != len(text) {
				return nil, fmt.Errorf("unsupported armour flag expression %q", text)
			}

			arguments, err := splitTopLevel(inside, ',')

			if err != nil || len(arguments) != 2 {
				return nil, fmt.Errorf("unsupported armour flag expression %q", text)
			}

			flag.ID = arguments[0].text
			flag.Level, err = propertyInt(arguments[1].text)

			if err != nil {
				return nil, err
			}
		} else if strings.HasPrefix(text, "ARMF_VUL_") {
			flag.Level = -1
		}

		if !knownSymbol(flag.ID, vocabulary.ArmourFlags) || flag.Level == 0 {
			return nil, fmt.Errorf("unknown armour flag %q", flag.ID)
		}

		flags = append(flags, flag)
	}

	sort.Slice(flags, func(i, j int) bool {
		return flags[i].ID < flags[j].ID
	})

	for i := 1; i < len(flags); i++ {
		if flags[i].ID == flags[i-1].ID {
			return nil, fmt.Errorf("duplicate armour flag %s", flags[i].ID)
		}
	}

	return flags, nil
}

func parseDamageFlags(raw string, vocabulary content.ItemVocabulary) ([]string, error) {
	parts, err := splitTopLevel(raw, '|')

	if err != nil {
		return nil, err
	}

	flags := make([]string, 0, len(parts))

	for _, part := range parts {
		if !knownSymbol(part.text, vocabulary.DamageFlags) {
			return nil, fmt.Errorf("unknown damage flag %q", part.text)
		}

		flags = append(flags, part.text)
	}

	sort.Strings(flags)

	return flags, nil
}

func parseBrandWeights(
	raw string,
	named map[string][]content.ItemBrandWeight,
	vocabulary content.ItemVocabulary,
) ([]content.ItemBrandWeight, error) {
	if !strings.HasPrefix(raw, "{") {
		weights, found := named[raw]

		if !found {
			return nil, fmt.Errorf("unknown weapon brand table %s", raw)
		}

		return append([]content.ItemBrandWeight(nil), weights...), nil
	}

	inside, end, err := balancedPart(raw, 0, '{', '}')

	if err != nil || end != len(raw) {
		return nil, fmt.Errorf("malformed weapon brand weights")
	}

	parts, err := splitTopLevel(inside, ',')

	if err != nil {
		return nil, err
	}

	var weights []content.ItemBrandWeight

	for _, part := range parts {
		fields, err := rowFields(part.text)

		if err != nil || len(fields) != 2 {
			return nil, fmt.Errorf("malformed weapon brand weight %q", part.text)
		}

		weight, err := propertyInt(fields[1])

		if err != nil {
			return nil, err
		}

		if !knownSymbol(fields[0], vocabulary.Brands) || weight < 0 {
			return nil, fmt.Errorf("unknown or invalid brand %s", fields[0])
		}

		weights = append(weights, content.ItemBrandWeight{
			BrandID: fields[0],
			Weight:  weight,
		})
	}

	sort.Slice(weights, func(i, j int) bool {
		return weights[i].BrandID < weights[j].BrandID
	})

	for i := 1; i < len(weights); i++ {
		if weights[i].BrandID == weights[i-1].BrandID {
			return nil, fmt.Errorf("duplicate weapon brand %s", weights[i].BrandID)
		}
	}

	return weights, nil
}

var brandTablePattern = regexp.MustCompile(`static\s+const\s+vector<brand_weight_tuple>\s+([A-Z][A-Z0-9_]*)\s*=`)

func parseNamedBrands(v sourceView, vocabulary content.ItemVocabulary) (map[string][]content.ItemBrandWeight, error) {
	named := map[string][]content.ItemBrandWeight{}

	for _, match := range brandTablePattern.FindAllStringSubmatchIndex(v.text, -1) {
		name := v.text[match[2]:match[3]]
		open := strings.Index(v.text[match[1]:], "{")

		if open < 0 {
			return nil, fmt.Errorf("%s:%d: brand table %s lacks initializer", v.path, v.line(match[0]), name)
		}

		open += match[1]
		inside, _, err := balancedPart(v.text, open, '{', '}')

		if err != nil {
			return nil, fmt.Errorf("%s:%d: brand table %s: %w", v.path, v.line(open), name, err)
		}

		weights, err := parseBrandWeights("{"+inside+"}", nil, vocabulary)

		if err != nil {
			return nil, fmt.Errorf("%s:%d: brand table %s: %w", v.path, v.line(open), name, err)
		}

		if _, found := named[name]; found {
			return nil, fmt.Errorf("%s:%d: duplicate brand table %s", v.path, v.line(open), name)
		}

		named[name] = weights
	}

	return named, nil
}

func armourRow(fields []string, vocabulary content.ItemVocabulary) (itemPropertyRow, error) {
	if len(fields) < 9 || len(fields) > 11 {
		return itemPropertyRow{}, fmt.Errorf("armour row has %d fields, want 9–11", len(fields))
	}

	name, err := propertyName(fields[1])

	if err != nil {
		return itemPropertyRow{}, err
	}

	for _, symbol := range []struct {
		id  string
		set []string
	}{
		{
			id:  fields[5],
			set: vocabulary.Slots,
		},
		{
			id:  fields[6],
			set: vocabulary.Sizes,
		},
		{
			id:  fields[7],
			set: vocabulary.Sizes,
		},
	} {
		if !knownSymbol(symbol.id, symbol.set) {
			return itemPropertyRow{}, fmt.Errorf("unknown armour symbol %s", symbol.id)
		}
	}

	p := content.ArmourProperties{
		SlotID:   fields[5],
		FitMinID: fields[6],
		FitMaxID: fields[7],
	}

	for _, field := range []struct {
		raw    string
		target *int
	}{
		{
			raw:    fields[2],
			target: &p.AC,
		},
		{
			raw:    fields[3],
			target: &p.EV,
		},
		{
			raw:    fields[4],
			target: &p.Price,
		},
	} {
		*field.target, err = propertyInt(field.raw)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	switch fields[8] {
	case "true":
		p.Mundane = true
	case "false":
	default:
		return itemPropertyRow{}, fmt.Errorf("unsupported armour mundane value %q", fields[8])
	}

	if len(fields) >= 10 {
		p.Flags, err = parseArmourFlags(fields[9], vocabulary)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	if len(fields) == 11 {
		p.AcquireWeight, err = propertyInt(fields[10])

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	return itemPropertyRow{
		Name:   name,
		Armour: &p,
	}, nil
}

func weaponRow(
	fields []string,
	named map[string][]content.ItemBrandWeight,
	vocabulary content.ItemVocabulary,
) (itemPropertyRow, error) {
	if len(fields) < 13 || len(fields) > 14 {
		return itemPropertyRow{}, fmt.Errorf("weapon row has %d fields, want 13–14", len(fields))
	}

	name, err := propertyName(fields[1])

	if err != nil {
		return itemPropertyRow{}, err
	}

	p := content.WeaponProperties{
		SkillID:     fields[5],
		Min2HSizeID: fields[6],
		Min1HSizeID: fields[7],
		AmmoID:      fields[8],
	}

	for _, symbol := range []struct {
		id  string
		set []string
	}{
		{
			id:  p.SkillID,
			set: vocabulary.Skills,
		},
		{
			id:  p.Min2HSizeID,
			set: vocabulary.Sizes,
		},
		{
			id:  p.Min1HSizeID,
			set: vocabulary.Sizes,
		},
		{
			id:  p.AmmoID,
			set: vocabulary.Ammo,
		},
	} {
		if !knownSymbol(symbol.id, symbol.set) {
			return itemPropertyRow{}, fmt.Errorf("unknown weapon symbol %s", symbol.id)
		}
	}

	for _, field := range []struct {
		raw    string
		target *int
	}{
		{
			raw:    fields[2],
			target: &p.Damage,
		},
		{
			raw:    fields[3],
			target: &p.Hit,
		},
		{
			raw:    fields[4],
			target: &p.Speed,
		},
		{
			raw:    fields[10],
			target: &p.Commonness,
		},
		{
			raw:    fields[11],
			target: &p.AcquireWeight,
		},
		{
			raw:    fields[12],
			target: &p.Price,
		},
	} {
		*field.target, err = propertyInt(field.raw)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	p.DamageFlags, err = parseDamageFlags(fields[9], vocabulary)

	if err != nil {
		return itemPropertyRow{}, err
	}

	if len(fields) == 14 {
		p.BrandWeights, err = parseBrandWeights(fields[13], named, vocabulary)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	return itemPropertyRow{
		Name:   name,
		Weapon: &p,
	}, nil
}

func missileRow(fields []string, vocabulary content.ItemVocabulary) (itemPropertyRow, error) {
	if len(fields) != 5 {
		return itemPropertyRow{}, fmt.Errorf("missile row has %d fields, want 5", len(fields))
	}

	if !knownSymbol(fields[0], vocabulary.Ammo) || fields[0] == "MI_NONE" {
		return itemPropertyRow{}, fmt.Errorf("unknown missile ID %s", fields[0])
	}

	name, err := propertyName(fields[1])

	if err != nil {
		return itemPropertyRow{}, err
	}

	p := content.MissileProperties{}

	for _, field := range []struct {
		raw    string
		target *int
	}{
		{
			raw:    fields[2],
			target: &p.Damage,
		},
		{
			raw:    fields[3],
			target: &p.MulchRate,
		},
		{
			raw:    fields[4],
			target: &p.Price,
		},
	} {
		*field.target, err = propertyInt(field.raw)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	return itemPropertyRow{
		Name:    name,
		Missile: &p,
	}, nil
}

func foodRow(fields []string) (itemPropertyRow, error) {
	if len(fields) != 5 {
		return itemPropertyRow{}, fmt.Errorf("food row has %d fields, want 5", len(fields))
	}

	name, err := propertyName(fields[1])

	if err != nil {
		return itemPropertyRow{}, err
	}

	p := content.FoodProperties{}

	for _, field := range []struct {
		raw    string
		target *int
	}{
		{
			raw:    fields[2],
			target: &p.NormalNutrition,
		},
		{
			raw:    fields[3],
			target: &p.CarnivoreNutrition,
		},
		{
			raw:    fields[4],
			target: &p.HerbivoreNutrition,
		},
	} {
		*field.target, err = propertyInt(field.raw)

		if err != nil {
			return itemPropertyRow{}, err
		}
	}

	return itemPropertyRow{
		Name: name,
		Food: &p,
	}, nil
}

func dragonArmourRows(raw string, vocabulary content.ItemVocabulary) (map[itemKey]itemPropertyRow, error) {
	open := strings.Index(raw, "(")

	if open < 0 || !strings.HasPrefix(raw, "DRAGON_ARMOUR") {
		return nil, fmt.Errorf("unsupported armour macro %q", raw)
	}

	inside, end, err := balancedPart(raw, open, '(', ')')

	if err != nil || end != len(raw) {
		return nil, fmt.Errorf("malformed DRAGON_ARMOUR call")
	}

	parts, err := splitTopLevel(inside, ',')

	if err != nil || len(parts) != 6 {
		return nil, fmt.Errorf("DRAGON_ARMOUR needs six arguments")
	}

	args := make([]string, 6)

	for i, p := range parts {
		args[i] = p.text
	}

	name, err := propertyName(args[1])

	if err != nil {
		return nil, err
	}

	flags, err := parseArmourFlags(args[5], vocabulary)

	if err != nil {
		return nil, err
	}

	ac, err := propertyInt(args[2])

	if err != nil {
		return nil, err
	}

	ev, err := propertyInt(args[3])

	if err != nil {
		return nil, err
	}

	price, err := propertyInt(args[4])

	if err != nil {
		return nil, err
	}

	copyFlags := func() []content.ItemFlag {
		return append([]content.ItemFlag(nil), flags...)
	}
	hideID := "ARM_" + args[0] + "_DRAGON_HIDE"
	scalesID := "ARM_" + args[0] + "_DRAGON_ARMOUR"

	return map[itemKey]itemPropertyRow{
		{"OBJ_ARMOUR", hideID}: {
			Name: "removed " + name + " dragon hide",
			Armour: &content.ArmourProperties{
				SlotID:   "EQ_BODY_ARMOUR",
				FitMinID: "SIZE_LITTLE",
				FitMaxID: "SIZE_GIANT",
				Flags:    copyFlags(),
			},
		},
		{"OBJ_ARMOUR", scalesID}: {
			Name: name + " dragon scales",
			Armour: &content.ArmourProperties{
				AC:            ac,
				EV:            ev,
				Price:         price,
				AcquireWeight: 25,
				SlotID:        "EQ_BODY_ARMOUR",
				FitMinID:      "SIZE_LITTLE",
				FitMaxID:      "SIZE_GIANT",
				Flags:         copyFlags(),
			},
		},
	}, nil
}

func parsePropertyTables(
	path string,
	data []byte,
	vocabulary content.ItemVocabulary,
) (map[itemKey]itemPropertyRow, error) {
	v, err := newSourceView(path, data)

	if err != nil {
		return nil, err
	}

	named, err := parseNamedBrands(v, vocabulary)

	if err != nil {
		return nil, err
	}

	result := map[itemKey]itemPropertyRow{}

	for _, table := range []struct {
		marker  string
		classID string
		decode  func([]string) (itemPropertyRow, error)
	}{
		{
			marker:  "Armour_prop[]",
			classID: "OBJ_ARMOUR",
			decode: func(fields []string) (itemPropertyRow, error) {
				return armourRow(fields, vocabulary)
			},
		},
		{
			marker:  "Weapon_prop[]",
			classID: "OBJ_WEAPONS",
			decode: func(fields []string) (itemPropertyRow, error) {
				return weaponRow(fields, named, vocabulary)
			},
		},
		{
			marker:  "Missile_prop[]",
			classID: "OBJ_MISSILES",
			decode: func(fields []string) (itemPropertyRow, error) {
				return missileRow(fields, vocabulary)
			},
		},
		{
			marker:  "Food_prop[]",
			classID: "OBJ_FOOD",
			decode:  foodRow,
		},
	} {
		inside, base, err := v.initializer(table.marker)

		if err != nil {
			return nil, err
		}

		parts, err := splitTopLevel(inside, ',')

		if err != nil {
			return nil, fmt.Errorf("%s:%d: %s: %w", path, v.line(base), table.marker, err)
		}

		for _, part := range parts {
			line := v.line(base + part.start)

			if part.text == "#undef DRAGON_ARMOUR" && table.classID == "OBJ_ARMOUR" {
				continue
			}

			if strings.HasPrefix(part.text, "DRAGON_ARMOUR") {
				if table.classID != "OBJ_ARMOUR" {
					return nil, fmt.Errorf("%s:%d: dragon macro outside armour table", path, line)
				}

				expanded, err := dragonArmourRows(part.text, vocabulary)

				if err != nil {
					return nil, fmt.Errorf("%s:%d: %w", path, line, err)
				}

				for key, row := range expanded {
					if _, found := result[key]; found {
						return nil, fmt.Errorf("%s:%d: duplicate property row %s", path, line, key.SubtypeID)
					}

					row.Line = line
					result[key] = row
				}

				continue
			}

			fields, err := rowFields(part.text)

			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line, err)
			}

			if len(fields) == 0 || !enumSymbolPattern.MatchString(fields[0]) {
				return nil, fmt.Errorf("%s:%d: invalid property ID", path, line)
			}

			row, err := table.decode(fields)

			if err != nil {
				return nil, fmt.Errorf("%s:%d: %s: %w", path, line, fields[0], err)
			}

			key := itemKey{
				ClassID:   table.classID,
				SubtypeID: fields[0],
			}

			if _, found := result[key]; found {
				return nil, fmt.Errorf("%s:%d: duplicate property row %s", path, line, fields[0])
			}

			row.Line = line
			result[key] = row
		}
	}

	return result, nil
}
