package itemimport

import (
	"fmt"

	"dcrawl-go/internal/content"
)

type itemPropertyRow struct {
	Name    string
	Line    int
	Armour  *content.ArmourProperties
	Weapon  *content.WeaponProperties
	Missile *content.MissileProperties
	Food    *content.FoodProperties
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
