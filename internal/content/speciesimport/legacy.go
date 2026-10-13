package speciesimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
)

var legacyRecord = regexp.MustCompile(`(?s)\{\s*(SP_[A-Z_]+)\s*,\s*\{(.*?)\}\s*\}\s*,`)
var legacyAptitude = regexp.MustCompile(`^\{\s*(SP_[A-Z_]+)\s*,\s*(SK_[A-Z_]+)\s*,\s*(-?\d+|UNUSABLE_SKILL)\s*\}\s*,?\s*$`)

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
	if len(fields) != 25 {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: expected 25 initializer fields, got %d", path, id, len(fields))
	}
	strings4 := [4]string{}
	for i := 0; i < 4; i++ {
		strings4[i], err = legacyString(fields[i])
		if err != nil {
			return content.SpeciesDef{}, fmt.Errorf("%s: %s: %w", path, id, err)
		}
	}
	flag := fields[4]
	if flag != "SPF_NONE" && !allowedFlags[flag] {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid flag %s", path, id, flag)
	}
	ints := map[int]int{}
	for _, i := range []int{5, 6, 7, 8, 13, 14, 15, 17} {
		ints[i], err = strconv.Atoi(fields[i])
		if err != nil {
			return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid integer %s", path, id, fields[i])
		}
	}
	if !strings.HasPrefix(fields[9], "MONS_") || !strings.HasPrefix(fields[10], "HT_") || !allowedUndead[fields[11]] || !strings.HasPrefix(fields[12], "SIZE_") {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid monster/habitat/undead/size fields", path, id)
	}
	statsField := strings.TrimSpace(fields[16])
	if !strings.HasPrefix(statsField, "{") || !strings.HasSuffix(statsField, "}") {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid level-up stats", path, id)
	}
	var stats []string
	for _, stat := range strings.Split(strings.Trim(statsField, "{} "), ",") {
		stat = strings.TrimSpace(stat)
		if stat == "" {
			continue
		}
		if !strings.HasPrefix(stat, "STAT_") {
			return content.SpeciesDef{}, fmt.Errorf("%s: %s: invalid level-up stat %s", path, id, stat)
		}
		stats = append(stats, strings.ToLower(strings.TrimPrefix(stat, "STAT_")))
	}
	for i := 18; i <= 22; i++ {
		if fields[i] != "{}" {
			return content.SpeciesDef{}, fmt.Errorf("%s: %s: unsupported legacy field %d", path, id, i)
		}
	}
	if fields[23] != "nullptr" || fields[24] != "nullptr" {
		return content.SpeciesDef{}, fmt.Errorf("%s: %s: unsupported legacy actions", path, id)
	}
	s := content.SpeciesDef{
		ID: id, MonsterID: fields[9], SourcePath: path, ShortName: strings4[0], Name: strings4[1], Adjective: strings4[2], Genus: strings4[3],
		XP: ints[5], HP: ints[6], MPMod: ints[7], MR: ints[8], Strength: ints[13], Intelligence: ints[14], Dexterity: ints[15],
		LevelUpStats: stats, LevelUpStatFrequency: ints[17], Habitat: fields[10], UndeadType: fields[11], Size: fields[12],
		Aptitudes: map[string]content.SpeciesAptitude{},
	}
	if flag != "SPF_NONE" {
		s.Flags = []string{flag}
	}
	return s, nil
}

func parseLegacy(speciesPath string, speciesText []byte, aptitudePath string, aptitudeText []byte) ([]content.SpeciesDef, error) {
	speciesLines, err := tag34Lines(speciesPath, speciesText)
	if err != nil {
		return nil, err
	}
	aptitudeLines, err := tag34Lines(aptitudePath, aptitudeText)
	if err != nil {
		return nil, err
	}
	source := strings.Join(speciesLines, "\n")
	matches := legacyRecord.FindAllStringSubmatchIndex(source, -1)
	if len(matches) != 3 {
		return nil, fmt.Errorf("%s: expected three legacy species, found %d", speciesPath, len(matches))
	}
	seen := map[string]bool{}
	byID := map[string]*content.SpeciesDef{}
	var records []content.SpeciesDef
	for _, match := range matches {
		id := source[match[2]:match[3]]
		if seen[id] {
			return nil, fmt.Errorf("%s: duplicate legacy species %s", speciesPath, id)
		}
		seen[id] = true
		record, err := parseLegacySpecies(speciesPath, id, source[match[4]:match[5]])
		if err != nil {
			return nil, err
		}
		records = append(records, record)
		byID[id] = &records[len(records)-1]
	}
	// Rebuild pointers after the append loop, since growing the slice may move it.
	for i := range records {
		byID[records[i].ID] = &records[i]
	}
	for _, line := range aptitudeLines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := legacyAptitude.FindStringSubmatch(line)
		if parts == nil {
			return nil, fmt.Errorf("%s: invalid aptitude row %s", aptitudePath, line)
		}
		record := byID[parts[1]]
		if record == nil {
			return nil, fmt.Errorf("%s: aptitude for unknown species %s", aptitudePath, parts[1])
		}
		if _, duplicate := record.Aptitudes[parts[2]]; duplicate {
			return nil, fmt.Errorf("%s: duplicate aptitude %s for %s", aptitudePath, parts[2], parts[1])
		}
		if parts[3] == "UNUSABLE_SKILL" {
			record.Aptitudes[parts[2]] = content.SpeciesAptitude{}
			continue
		}
		value, err := strconv.Atoi(parts[3])
		if err != nil || value < -10 || value > 10 {
			return nil, fmt.Errorf("%s: invalid aptitude %s for %s", aptitudePath, parts[2], parts[1])
		}
		record.Aptitudes[parts[2]] = content.SpeciesAptitude{Allowed: true, Value: value}
	}
	for _, record := range records {
		if len(record.Aptitudes) == 0 {
			return nil, fmt.Errorf("%s: missing aptitudes for %s", aptitudePath, record.ID)
		}
	}
	sort.Slice(records, func(i, j int) bool { return records[i].ID < records[j].ID })
	return records, nil
}
