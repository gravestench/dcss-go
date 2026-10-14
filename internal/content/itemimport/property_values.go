package itemimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
)

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
	index := sort.SearchStrings(list, symbol)

	return index < len(list) && list[index] == symbol
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

var brandTablePattern = regexp.MustCompile(
	`static\s+const\s+vector<brand_weight_tuple>\s+([A-Z][A-Z0-9_]*)\s*=`,
)

func parseNamedBrands(
	v sourceView,
	vocabulary content.ItemVocabulary,
) (map[string][]content.ItemBrandWeight, error) {
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
