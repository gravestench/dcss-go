package itemimport

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/content"
)

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
