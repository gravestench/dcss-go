package itemimport

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/content"
)

func dragonArmourRows(
	raw string,
	vocabulary content.ItemVocabulary,
) (map[itemKey]itemPropertyRow, error) {
	open := strings.Index(raw, "(")

	if open < 0 || !strings.HasPrefix(raw, "DRAGON_ARMOUR") {
		return nil, fmt.Errorf("unsupported armour macro %q", raw)
	}

	inside, end, err := balancedPart(raw, open, '(', ')')

	if err != nil ||
		end != len(raw) {
		return nil, fmt.Errorf("malformed DRAGON_ARMOUR call")
	}

	parts, err := splitTopLevel(inside, ',')

	if err != nil ||
		len(parts) != 6 {
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
		itemKey{
			ClassID:   "OBJ_ARMOUR",
			SubtypeID: hideID,
		}: {
			Name: "removed " + name + " dragon hide",
			Armour: &content.ArmourProperties{
				SlotID:   "EQ_BODY_ARMOUR",
				FitMinID: "SIZE_LITTLE",
				FitMaxID: "SIZE_GIANT",
				Flags:    copyFlags(),
			},
		},

		itemKey{
			ClassID:   "OBJ_ARMOUR",
			SubtypeID: scalesID,
		}: {
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
