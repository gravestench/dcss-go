package speciesimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var legacyRecord = regexp.MustCompile(`(?s)\{\s*(SP_[A-Z_]+)\s*,\s*\{(.*?)\}\s*\}\s*,`)

var legacyAptitude = regexp.MustCompile(
	`^\{\s*(SP_[A-Z_]+)\s*,\s*(SK_[A-Z_]+)\s*,\s*` +
		`(-?\d+|UNUSABLE_SKILL)\s*\}\s*,?\s*$`,
)

// The tag-34 aggregate has no field names in C++. Keep its exact order here
// so an upstream source change cannot silently shift a species property.
const (
	legacyShortName = iota
	legacyName
	legacyAdjective
	legacyGenus
	legacyFlags
	legacyXP
	legacyHP
	legacyMPMod
	legacyMR
	legacyMonster
	legacyHabitat
	legacyUndeadType
	legacySize
	legacyStrength
	legacyIntelligence
	legacyDexterity
	legacyLevelUpStats
	legacyLevelUpFrequency
)

const (
	legacyUnusedStart = 18
	legacyUnusedEnd   = 22
	legacyWalkingVerb = 23
	legacyAltarAction = 24
	legacyFieldCount  = 25
)

func splitLegacyFields(body string) ([]string, error) {
	var fields []string
	depth, quoted, escaped := 0, false, false
	start := 0

	for i, ch := range body {
		switch {
		case quoted && escaped:
			escaped = false

		case quoted && ch == '\\':
			escaped = true

		case ch == '"':
			quoted = !quoted

		case !quoted && ch == '{':
			depth++

		case !quoted && ch == '}':
			depth--

		case !quoted && ch == ',' && depth == 0:
			fields = append(fields, strings.TrimSpace(body[start:i]))
			start = i + 1
		}

		if depth < 0 {
			return nil, fmt.Errorf("unbalanced legacy braces")
		}
	}

	if depth != 0 || quoted {
		return nil, fmt.Errorf("unbalanced legacy fields")
	}

	if tail := strings.TrimSpace(body[start:]); tail != "" {
		fields = append(fields, tail)
	}

	return fields, nil
}

func legacyString(field string) (string, error) {
	value, err := strconv.Unquote(field)

	if err != nil {
		return "", fmt.Errorf("invalid quoted string %s", field)
	}

	return value, nil
}

func parseLegacySpecies(path, id, body string) (content.SpeciesDef, error) {
	fields, err := splitLegacyFields(body)

	if err != nil {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: %w", path, id, err)
	}

	if len(fields) != legacyFieldCount {
		return content.SpeciesDef{}, fmt.Errorf(
			"%s: %s: expected 25 initializer fields, got %d",
			path, id, len(fields),
		)
	}

	names := [4]string{}

	for index := legacyShortName; index <= legacyGenus; index++ {
		names[index], err = legacyString(fields[index])

		if err != nil {
			return content.SpeciesDef{}, fmt.Errorf("%s: %s: %w", path, id, err)
		}
	}

	flag := fields[legacyFlags]

	if flag != "SPF_NONE" && !allowedFlags[flag] {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid flag %s", path, id, flag)
	}

	numbers := map[int]int{}

	for _, index := range []int{
		legacyXP,
		legacyHP,
		legacyMPMod,
		legacyMR,
		legacyStrength,
		legacyIntelligence,
		legacyDexterity,
		legacyLevelUpFrequency,
	} {
		numbers[index], err = strconv.Atoi(fields[index])

		if err != nil {
			return content.SpeciesDef{}, fmt.Errorf(
				"%s: %s: invalid integer %s",
				path, id, fields[index],
			)
		}
	}

	if !strings.HasPrefix(fields[legacyMonster], "MONS_") ||
		!strings.HasPrefix(fields[legacyHabitat], "HT_") ||
		!allowedUndead[fields[legacyUndeadType]] ||
		!strings.HasPrefix(fields[legacySize], "SIZE_") {
		return content.SpeciesDef{}, fmt.Errorf(
			"%s: %s: invalid monster/habitat/undead/size fields",
			path, id,
		)
	}

	stats, err := parseLegacyStats(path, id, fields[legacyLevelUpStats])

	if err != nil {
		return content.SpeciesDef{}, err
	}

	if err := validateLegacyTail(path, id, fields); err != nil {
		return content.SpeciesDef{}, err
	}

	s := content.SpeciesDef{
		ID:         id,
		MonsterID:  fields[legacyMonster],
		SourcePath: path,

		ShortName: names[legacyShortName],
		Name:      names[legacyName],
		Adjective: names[legacyAdjective],
		Genus:     names[legacyGenus],

		XP:    numbers[legacyXP],
		HP:    numbers[legacyHP],
		MPMod: numbers[legacyMPMod],
		MR:    numbers[legacyMR],

		Strength:             numbers[legacyStrength],
		Intelligence:         numbers[legacyIntelligence],
		Dexterity:            numbers[legacyDexterity],
		LevelUpStats:         stats,
		LevelUpStatFrequency: numbers[legacyLevelUpFrequency],

		Habitat:    fields[legacyHabitat],
		UndeadType: fields[legacyUndeadType],
		Size:       fields[legacySize],

		Aptitudes: map[string]content.SpeciesAptitude{},
	}

	if flag != "SPF_NONE" {
		s.Flags = []string{flag}
	}

	return s, nil
}

func parseLegacyStats(path, id, raw string) ([]string, error) {
	field := strings.TrimSpace(raw)

	if !strings.HasPrefix(field, "{") || !strings.HasSuffix(field, "}") {
		return nil, fmt.Errorf("%s: %s: invalid level-up stats", path, id)
	}

	var stats []string

	for _, stat := range strings.Split(strings.Trim(field, "{} "), ",") {
		stat = strings.TrimSpace(stat)

		if stat == "" {
			continue
		}

		if !strings.HasPrefix(stat, "STAT_") {
			return nil, fmt.Errorf("%s: %s: invalid level-up stat %s", path, id, stat)
		}

		stats = append(stats, strings.ToLower(strings.TrimPrefix(stat, "STAT_")))
	}

	return stats, nil
}

func validateLegacyTail(path, id string, fields []string) error {
	for index := legacyUnusedStart; index <= legacyUnusedEnd; index++ {
		if fields[index] != "{}" {
			return fmt.Errorf("%s: %s: unsupported legacy field %d", path, id, index)
		}
	}

	if fields[legacyWalkingVerb] != "nullptr" ||
		fields[legacyAltarAction] != "nullptr" {
		return fmt.Errorf("%s: %s: unsupported legacy actions", path, id)
	}

	return nil
}

func parseLegacy(
	speciesPath string,
	speciesText []byte,
	aptitudePath string,
	aptitudeText []byte,
) ([]content.SpeciesDef, error) {
	speciesLines, err := sourceparse.Tag34Lines(speciesPath, speciesText)

	if err != nil {
		return nil, err
	}

	aptitudeLines, err := sourceparse.Tag34Lines(aptitudePath, aptitudeText)

	if err != nil {
		return nil, err
	}

	records, err := parseLegacyRecords(speciesPath, strings.Join(speciesLines, "\n"))

	if err != nil {
		return nil, err
	}

	if err := attachLegacyAptitudes(aptitudePath, aptitudeLines, records); err != nil {
		return nil, err
	}

	sort.Slice(records, func(i, j int) bool {
		return records[i].ID < records[j].ID
	})

	return records, nil
}

func parseLegacyRecords(path, source string) ([]content.SpeciesDef, error) {
	matches := legacyRecord.FindAllStringSubmatchIndex(source, -1)

	if len(matches) != 3 {
		return nil, fmt.Errorf("%s: expected three legacy species, found %d", path, len(matches))
	}

	seen := map[string]bool{}
	var records []content.SpeciesDef

	for _, match := range matches {
		id := source[match[2]:match[3]]

		if seen[id] {
			return nil, fmt.Errorf("%s: duplicate legacy species %s", path, id)
		}

		seen[id] = true
		record, err := parseLegacySpecies(path, id, source[match[4]:match[5]])

		if err != nil {
			return nil, err
		}

		records = append(records, record)
	}

	return records, nil
}

func attachLegacyAptitudes(
	path string,
	lines []string,
	records []content.SpeciesDef,
) error {
	byID := make(map[string]*content.SpeciesDef, len(records))

	for index := range records {
		byID[records[index].ID] = &records[index]
	}

	for _, line := range lines {
		line = strings.TrimSpace(line)

		if line == "" {
			continue
		}

		parts := legacyAptitude.FindStringSubmatch(line)

		if parts == nil {
			return fmt.Errorf("%s: invalid aptitude row %s", path, line)
		}

		record := byID[parts[1]]

		if record == nil {
			return fmt.Errorf("%s: aptitude for unknown species %s", path, parts[1])
		}

		if _, duplicate := record.Aptitudes[parts[2]]; duplicate {
			return fmt.Errorf("%s: duplicate aptitude %s for %s", path, parts[2], parts[1])
		}

		if parts[3] == "UNUSABLE_SKILL" {
			record.Aptitudes[parts[2]] = content.SpeciesAptitude{}
			continue
		}

		value, err := strconv.Atoi(parts[3])

		if err != nil ||
			value < -10 || value > 10 {
			return fmt.Errorf("%s: invalid aptitude %s for %s", path, parts[2], parts[1])
		}

		record.Aptitudes[parts[2]] = content.SpeciesAptitude{
			Allowed: true,
			Value:   value,
		}
	}

	for _, record := range records {
		if len(record.Aptitudes) == 0 {
			return fmt.Errorf("%s: missing aptitudes for %s", path, record.ID)
		}
	}

	return nil
}
