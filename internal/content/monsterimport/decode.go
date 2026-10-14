package monsterimport

import (
	"fmt"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
)

// symbolSets are built from the active pinned enum declarations by import.go.
type symbolSets struct {
	monster, attackType, attackFlavour, spellbook, classFlag, resistance                map[string]bool
	holiness, shout, intelligence, habitat, itemUse, size, shape, colour, tileVariation map[string]bool
}

func checked(value string, symbols map[string]bool) (string, error) {
	value = strings.TrimSpace(value)

	if !symbols[value] {
		return "", fmt.Errorf("unknown symbol %q", value)
	}

	return value, nil
}

func number(value string) (int, error) {
	value = strings.TrimSpace(value)

	if value == "WILL_INVULN" {
		return 5000, nil
	} // defines.h:154

	n, err := strconv.Atoi(value)

	if err != nil {
		return 0, fmt.Errorf("unsupported integer expression %q", value)
	}

	return n, nil
}

func orTerms(expr string) ([]string, error) {
	var parts []string
	start, depth := 0, 0

	for i, c := range expr {
		switch c {
		case '(':
			depth++
		case ')':
			depth--
		case '|':
			if depth == 0 {
				parts = append(parts, strings.TrimSpace(expr[start:i]))
				start = i + 1
			}
		}

		if depth < 0 {
			return nil, fmt.Errorf("unbalanced OR expression %q", expr)
		}
	}

	if depth != 0 {
		return nil, fmt.Errorf("unbalanced OR expression %q", expr)
	}

	parts = append(parts, strings.TrimSpace(expr[start:]))

	for _, part := range parts {
		if part == "" {
			return nil, fmt.Errorf("empty OR term in %q", expr)
		}
	}

	return parts, nil
}

func decodeFlags(expr string, symbols map[string]bool) ([]string, error) {
	terms, err := orTerms(expr)

	if err != nil {
		return nil, err
	}

	var flags []string
	seen := map[string]bool{}

	for _, term := range terms {
		if term == "M_NOT_DANGEROUS" { // mon-data.h:121
			for _, expanded := range []string{"M_NO_EXP_GAIN", "M_NO_THREAT"} {
				if !symbols[expanded] {
					return nil, fmt.Errorf("missing flag alias target %s", expanded)
				}

				if !seen[expanded] {
					flags = append(flags, expanded)
					seen[expanded] = true
				}
			}

			continue
		}

		if _, err := checked(term, symbols); err != nil {
			return nil, err
		}

		if term != "M_NO_FLAGS" && !seen[term] {
			flags = append(flags, term)
			seen[term] = true
		}
	}

	return flags, nil
}

func decodeHoliness(expr string, symbols map[string]bool) ([]string, error) {
	terms, err := orTerms(expr)

	if err != nil {
		return nil, err
	}

	var result []string

	for _, term := range terms {
		if _, err := checked(term, symbols); err != nil {
			return nil, err
		}

		result = append(result, term)
	}

	return result, nil
}

func decodeResistances(expr string, symbols map[string]bool) ([]content.MonsterResistance, error) {
	terms, err := orTerms(expr)

	if err != nil {
		return nil, err
	}
	// The seven low bits of each three-bit slot encode signed levels; OR
	// source terms at the bit level before decoding, as mon-enum.h does.
	levels := map[string]int{}
	var order []string
	add := func(id string, level int) error {
		if !symbols[id] {
			return fmt.Errorf("unknown resistance %q", id)
		}

		if !strings.HasPrefix(id, "MR_RES_") && id != "MR_OLD_RES_ACID" && id != "MR_VUL_WATER" {
			return fmt.Errorf("invalid resistance %q", id)
		}

		if _, exists := levels[id]; !exists {
			order = append(order, id)
		}

		levels[id] |= level & 7

		return nil
	}

	for _, term := range terms {
		if term == "MR_NO_FLAGS" {
			if !symbols[term] {
				return nil, fmt.Errorf("unknown resistance %q", term)
			}

			continue
		}

		if strings.HasPrefix(term, "mrd(") {
			inner, end, err := balanced(term, len("mrd"), '(', ')')

			if err != nil || end != len(term) {
				return nil, fmt.Errorf("unsupported resistance macro %q", term)
			}

			args, err := splitFields(inner)

			if err != nil || len(args) != 2 {
				return nil, fmt.Errorf("bad mrd arguments %q", term)
			}

			level, err := number(args[1])

			if err != nil || level < -4 || level > 4 {
				return nil, fmt.Errorf("invalid mrd level %q", args[1])
			}

			bases, err := orTerms(args[0])

			if err != nil {
				return nil, err
			}

			for _, id := range bases {
				if err := add(id, level); err != nil {
					return nil, err
				}
			}

			continue
		}

		if strings.HasPrefix(term, "MR_VUL_") && term != "MR_VUL_WATER" {
			if !symbols[term] {
				return nil, fmt.Errorf("unknown resistance %q", term)
			}

			if err := add("MR_RES_"+strings.TrimPrefix(term, "MR_VUL_"), -1); err != nil {
				return nil, err
			}

			continue
		}

		if err := add(term, 1); err != nil {
			return nil, err
		}
	}

	var result []content.MonsterResistance

	for _, id := range order {
		level := levels[id]

		if level > 4 {
			level -= 8
		}

		if level != 0 {
			result = append(result, content.MonsterResistance{
				ID:    id,
				Level: level,
			})
		}
	}

	return result, nil
}

func decodeAttacks(expr string, types, flavours map[string]bool) ([4]content.MonsterAttack, error) {
	var result [4]content.MonsterAttack
	inner, end, err := balanced(strings.TrimSpace(expr), 0, '{', '}')

	if err != nil || end != len(strings.TrimSpace(expr)) {
		return result, fmt.Errorf("invalid attack initializer %q", expr)
	}

	parts, err := splitFields(inner)

	if err != nil || len(parts) != 4 {
		return result, fmt.Errorf("expected four attacks in %q", expr)
	}

	for i, part := range parts {
		if part == "AT_NO_ATK" {
			part = "{AT_NONE, AF_PLAIN, 0}"
		}

		value, end, err := balanced(part, 0, '{', '}')

		if err != nil || end != len(part) {
			return result, fmt.Errorf("invalid attack %q", part)
		}

		fields, err := splitFields(value)

		if err != nil || len(fields) != 3 {
			return result, fmt.Errorf("invalid attack fields %q", part)
		}

		typeID, err := checked(fields[0], types)

		if err != nil {
			return result, err
		}

		flavour, err := checked(fields[1], flavours)

		if err != nil {
			return result, err
		}

		damage, err := number(fields[2])

		if err != nil || damage < 0 {
			return result, fmt.Errorf("invalid attack damage %q", fields[2])
		}

		result[i] = content.MonsterAttack{
			TypeID:    typeID,
			FlavourID: flavour,
			Damage:    damage,
		}
	}

	return result, nil
}

func decodeEnergy(expr string) (content.MonsterEnergy, error) {
	base := []int{
		10,
		10,
		10,
		10,
		10,
		10,
		10,
		100,
	}
	expr = strings.TrimSpace(expr)

	if expr != "DEFAULT_ENERGY" {
		if strings.HasPrefix(expr, "{") {
			inner, end, err := balanced(expr, 0, '{', '}')

			if err != nil || end != len(expr) {
				return content.MonsterEnergy{}, fmt.Errorf("bad energy initializer %q", expr)
			}

			parts, err := splitFields(inner)

			if err != nil || len(parts) != 8 {
				return content.MonsterEnergy{}, fmt.Errorf("energy needs eight costs")
			}

			for i, part := range parts {
				base[i], err = number(part)

				if err != nil {
					return content.MonsterEnergy{}, err
				}
			}
		} else {
			open := strings.IndexByte(expr, '(')

			if open < 0 {
				return content.MonsterEnergy{}, fmt.Errorf("unknown energy macro %q", expr)
			}

			inner, end, err := balanced(expr, open, '(', ')')

			if err != nil || end != len(expr) {
				return content.MonsterEnergy{}, fmt.Errorf("bad energy macro %q", expr)
			}

			value, err := number(inner)

			if err != nil {
				return content.MonsterEnergy{}, err
			}

			switch expr[:open] {
			case "MOVE_ENERGY":
				base[0], base[1] = value, value
			case "ACTION_ENERGY":
				for i := 2; i <= 6; i++ {
					base[i] = value
				}

				base[7] = value * 10
			case "ATTACK_ENERGY":
				base[2] = value
			case "MISSILE_ENERGY":
				base[3] = value
			case "SPELL_ENERGY":
				base[4] = value
			case "SWIM_ENERGY":
				base[1] = value
			default:
				return content.MonsterEnergy{}, fmt.Errorf("unknown energy macro %q", expr)
			}
		}
	}

	for _, value := range base {
		if value < 0 || value > 255 {
			return content.MonsterEnergy{}, fmt.Errorf("energy cost out of range")
		}
	}

	return content.MonsterEnergy{
		Move:          base[0],
		Swim:          base[1],
		Attack:        base[2],
		Missile:       base[3],
		Spell:         base[4],
		Special:       base[5],
		Item:          base[6],
		PickupPercent: base[7],
	}, nil
}

func decodeTile(expr string, variations map[string]bool) (content.MonsterTile, error) {
	var tile content.MonsterTile
	expr = strings.TrimSpace(expr)
	inner, end, err := balanced(expr, 0, '{', '}')

	if err != nil || end != len(expr) {
		return tile, fmt.Errorf("bad tile initializer %q", expr)
	}

	parts, err := splitFields(inner)

	if err != nil || len(parts) < 1 || len(parts) > 2 {
		return tile, fmt.Errorf("bad tile fields %q", expr)
	}

	tile.ID = strings.TrimSpace(parts[0])

	if !validTile(tile.ID) {
		return tile, fmt.Errorf("unknown tile %q", tile.ID)
	}

	tile.VariationID = "TVARY_NONE"

	if len(parts) == 2 {
		tile.VariationID, err = checked(parts[1], variations)

		if err != nil {
			return tile, err
		}
	}

	return tile, nil
}

func validTile(id string) bool {
	if id == "TILE_ERROR" {
		return true
	}

	if !strings.HasPrefix(id, "TILEP_") && !strings.HasPrefix(id, "TILE_") {
		return false
	}

	for _, r := range id {
		if !(r >= 'A' && r <= 'Z') && !(r >= '0' && r <= '9') && r != '_' {
			return false
		}
	}

	return true
}

func decodeRows(path string, rows []sourceRow, symbols symbolSets) ([]content.MonsterDef, error) {
	defs := make([]content.MonsterDef, 0, len(rows))

	for _, row := range rows {
		def, err := decodeRow(path, row, symbols)

		if err != nil {
			return nil, fmt.Errorf("%s:%d: %s: %w", path, row.Line, row.ID, err)
		}

		defs = append(defs, def)
	}

	return defs, nil
}

func decodeRow(path string, row sourceRow, s symbolSets) (content.MonsterDef, error) {
	d := content.MonsterDef{
		ID:         row.ID,
		SourcePath: path,
		SourceLine: row.Line,
		Status:     content.MonsterDefined,
	}

	if row.Removed {
		d.Status = content.MonsterRemoved
		d.Name = row.RemovedName

		return d, nil
	}

	f := row.Fields

	if len(f) != 28 || f[0] != row.ID {
		return d, fmt.Errorf("expected 28 fields for matching monster ID")
	}

	if _, err := checked(row.ID, s.monster); err != nil {
		return d, err
	}

	glyph, err := strconv.Unquote(f[1])

	if err != nil || len([]rune(glyph)) != 1 {
		return d, fmt.Errorf("invalid glyph %q", f[1])
	}

	d.Glyph = []rune(glyph)[0]

	if d.ColourID, err = checked(f[2], s.colour); err != nil {
		return d, err
	}

	if d.Name, err = strconv.Unquote(f[3]); err != nil {
		return d, fmt.Errorf("invalid name %q", f[3])
	}

	if d.Flags, err = decodeFlags(f[4], s.classFlag); err != nil {
		return d, err
	}

	if d.Resistances, err = decodeResistances(f[5], s.resistance); err != nil {
		return d, err
	}

	if d.XPModifier, err = number(f[6]); err != nil {
		return d, err
	}

	if d.GenusID, err = checked(f[7], s.monster); err != nil {
		return d, err
	}

	if d.SpeciesID, err = checked(f[8], s.monster); err != nil {
		return d, err
	}

	if d.Holiness, err = decodeHoliness(f[9], s.holiness); err != nil {
		return d, err
	}

	if d.Willpower, err = number(f[10]); err != nil {
		return d, err
	}

	if d.Attacks, err = decodeAttacks(f[11], s.attackType, s.attackFlavour); err != nil {
		return d, err
	}

	for i, target := range []*int{
		&d.HD,
		&d.AverageHP10x,
		&d.AC,
		&d.EV,
	} {
		if *target, err = number(f[12+i]); err != nil {
			return d, err
		}
	}

	if d.SpellbookID, err = checked(f[16], s.spellbook); err != nil {
		return d, err
	}

	switch f[17] {
	case "true":
		d.LeavesCorpse = true
	case "false":
	default:
		return d, fmt.Errorf("invalid corpse boolean %q", f[17])
	}

	if d.ShoutID, err = checked(f[18], s.shout); err != nil {
		return d, err
	}

	if d.IntelligenceID, err = checked(f[19], s.intelligence); err != nil {
		return d, err
	}

	if d.HabitatID, err = checked(f[20], s.habitat); err != nil {
		return d, err
	}

	if d.Speed, err = number(f[21]); err != nil {
		return d, err
	}

	if d.Energy, err = decodeEnergy(f[22]); err != nil {
		return d, err
	}

	if d.ItemUseID, err = checked(f[23], s.itemUse); err != nil {
		return d, err
	}

	if d.SizeID, err = checked(f[24], s.size); err != nil {
		return d, err
	}

	if d.ShapeID, err = checked(f[25], s.shape); err != nil {
		return d, err
	}

	if d.Tile, err = decodeTile(f[26], s.tileVariation); err != nil {
		return d, err
	}

	d.CorpseTileID = strings.TrimSpace(f[27])

	if d.CorpseTileID != "0" && !validTile(d.CorpseTileID) {
		return d, fmt.Errorf("unknown corpse tile %q", d.CorpseTileID)
	}

	return d, nil
}
