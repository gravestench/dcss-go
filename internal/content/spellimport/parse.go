package spellimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var spellID = regexp.MustCompile(`^SPELL_[A-Z0-9_]+$`)

var enumLine = regexp.MustCompile(`^(SPELL_[A-Z0-9_]+)(?:\s*=\s*(SPELL_[A-Z0-9_]+))?,?$`)

var axedLine = regexp.MustCompile(`^AXED_SPELL\((SPELL_[A-Z0-9_]+),\s*("(?:\\.|[^"])*")\)$`)

var vocabularyLine = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_]*)\s*=`)

func parseVocabulary(path string, body []byte, name string) (map[string]bool, error) {
	source := string(body)
	start := strings.Index(source, "enum class "+name)

	if start < 0 {
		return nil, fmt.Errorf("%s: missing %s enum", path, name)
	}

	end := strings.Index(source[start:], "};")

	if end < 0 {
		return nil, fmt.Errorf("%s: unterminated %s enum", path, name)
	}

	section := source[start : start+end+2]
	lines, err := sourceparse.Tag34NumberedLines(path, []byte(section))

	if err != nil {
		return nil, err
	}

	values := map[string]bool{}

	for _, line := range lines {
		if match := vocabularyLine.FindStringSubmatch(strings.TrimSpace(line.Text)); match != nil {
			values[match[1]] = true
		}
	}

	if !values["none"] {
		return nil, fmt.Errorf("%s: %s vocabulary lacks none", path, name)
	}

	return values, nil
}

func parseEnum(path string, body []byte) ([]content.SpellDef, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	inside, done, sawCount := false, false, false
	var spells []content.SpellDef

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			if strings.HasPrefix(value, "enum spell_type") {
				inside = true
			}

			continue
		}

		if value == "{" {
			continue
		}

		if value == "};" {
			done = true
			break
		}

		if value == "" {
			continue
		}

		if value == "NUM_SPELLS" || value == "NUM_SPELLS," {
			sawCount = true
			continue
		}

		match := enumLine.FindStringSubmatch(value)

		if match == nil {
			return nil, fmt.Errorf("%s:%d: malformed spell enum row %q", path, line.Number, value)
		}

		if match[2] != "" {
			if match[1] != "SPELL_FIRST_SPELL" {
				return nil, fmt.Errorf("%s:%d: unsupported spell alias %q", path, line.Number, value)
			}

			continue
		}

		spells = append(spells, content.SpellDef{
			ID:        match[1],
			NumericID: len(spells),
			EnumLine:  line.Number,
		})
	}

	if !inside || !done || !sawCount || len(spells) == 0 {
		return nil, fmt.Errorf("%s: incomplete spell enum", path)
	}

	return spells, nil
}

func splitCSV(value string) ([]string, error) {
	var fields []string
	var start int
	quoted, escaped := false, false

	for i, char := range value {
		switch {
		case escaped:
			escaped = false

		case char == '\\' && quoted:
			escaped = true

		case char == '"':
			quoted = !quoted

		case char == ',' && !quoted:
			field := strings.TrimSpace(value[start:i])

			if field != "" {
				fields = append(fields, field)
			}

			start = i + 1
		}
	}

	if quoted {
		return nil, fmt.Errorf("unterminated spell string")
	}

	if rest := strings.TrimSpace(value[start:]); rest != "" {
		fields = append(fields, rest)
	}

	return fields, nil
}

func parseBits(value, namespace string) ([]string, error) {
	var result []string

	for _, part := range strings.Split(value, "|") {
		part = strings.TrimSpace(part)

		if !strings.HasPrefix(part, namespace+"::") {
			return nil, fmt.Errorf("unsupported %s expression %q", namespace, value)
		}

		name := strings.TrimSpace(strings.TrimPrefix(part, namespace+"::"))

		if !regexp.MustCompile(`^[A-Za-z_][A-Za-z0-9_]*$`).MatchString(name) {
			return nil, fmt.Errorf("bad %s symbol %q", namespace, name)
		}

		result = append(result, name)
	}

	return result, nil
}

func parseDescriptor(path string, line int, fields []string) (content.SpellDef, error) {
	if len(fields) != 11 || !spellID.MatchString(fields[0]) {
		return content.SpellDef{}, fmt.Errorf("%s:%d: expected eleven spell fields, got %d", path, line, len(fields))
	}

	name, err := strconv.Unquote(fields[1])

	if err != nil {
		return content.SpellDef{}, fmt.Errorf("%s:%d: spell name: %w", path, line, err)
	}

	schools, err := parseBits(fields[2], "spschool")

	if err != nil {
		return content.SpellDef{}, fmt.Errorf("%s:%d: %w", path, line, err)
	}

	flags, err := parseBits(fields[3], "spflag")

	if err != nil {
		return content.SpellDef{}, fmt.Errorf("%s:%d: %w", path, line, err)
	}

	ints := make([]int, 4)

	for i, column := range []int{
		4,
		5,
		8,
		9,
	} {
		ints[i], err = strconv.Atoi(fields[column])

		if err != nil {
			return content.SpellDef{}, fmt.Errorf("%s:%d: numeric field %d: %w", path, line, column, err)
		}
	}

	return content.SpellDef{
		ID:           fields[0],
		Name:         name,
		Status:       content.SpellDefined,
		Schools:      schools,
		Flags:        flags,
		Level:        ints[0],
		PowerCap:     ints[1],
		MinRangeExpr: strings.Join(strings.Fields(fields[6]), " "),
		MaxRangeExpr: strings.Join(strings.Fields(fields[7]), " "),
		Noise:        ints[2],
		EffectNoise:  ints[3],
		TileID:       fields[10],
		SourcePath:   "crawl-ref/source/spl-data.h",
		SourceLine:   line,
	}, nil
}

func parseSpells(path string, body []byte) (map[string]content.SpellDef, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	result := map[string]content.SpellDef{}

	var inside bool
	var tableOpened bool
	var block bool
	var closed bool
	var macro bool
	var macroBody bool
	start := 0
	axedCount := 0
	var data strings.Builder

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			if strings.Contains(value, "spelldata[]") {
				inside = true

				if strings.HasSuffix(value, "{") {
					tableOpened = true
				}
			}

			continue
		}

		if value == "" {
			continue
		}

		if !tableOpened {
			if value != "{" {
				return nil, fmt.Errorf("%s:%d: missing spell table opening brace", path, line.Number)
			}

			tableOpened = true
			continue
		}

		if block && value != "}," {
			data.WriteString(value)
			data.WriteByte(' ')
			continue
		}

		if value == "};" {
			closed = true
			break
		}

		if strings.HasPrefix(value, "#define AXED_SPELL") {
			if macro || value != `#define AXED_SPELL(tag, name) \` {
				return nil, fmt.Errorf("%s:%d: unsupported AXED_SPELL macro", path, line.Number)
			}

			macro = true
			continue
		}

		if macro && !macroBody && strings.HasPrefix(value, "{ tag, name,") {
			if strings.Join(
				strings.Fields(value),
				" ",
			) != "{ tag, name, spschool::none, spflag::none, 7, 0, -1, -1, 0, 0, TILEG_ERROR }," {
				return nil, fmt.Errorf("%s:%d: unsupported AXED_SPELL expansion", path, line.Number)
			}

			macroBody = true
			continue
		}

		if match := axedLine.FindStringSubmatch(value); match != nil {
			axedCount++
			name, err := strconv.Unquote(match[2])

			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line.Number, err)
			}

			if _, duplicate := result[match[1]]; duplicate {
				return nil, fmt.Errorf("%s:%d: duplicate spell %s", path, line.Number, match[1])
			}

			result[match[1]] = content.SpellDef{
				ID:           match[1],
				Name:         name,
				Status:       content.SpellRemoved,
				Schools:      []string{"none"},
				Flags:        []string{"none"},
				Level:        7,
				MinRangeExpr: "-1",
				MaxRangeExpr: "-1",
				TileID:       "TILEG_ERROR",
				SourcePath:   "crawl-ref/source/spl-data.h",
				SourceLine:   line.Number,
			}
			continue
		}

		if value == "{" || strings.HasPrefix(value, "{ SPELL_") {
			block, start = true, line.Number
			data.Reset()

			if value != "{" {
				data.WriteString(strings.TrimSpace(strings.TrimPrefix(value, "{")))
				data.WriteByte(' ')
			}

			continue
		}

		if value == "}," {
			if !block {
				return nil, fmt.Errorf("%s:%d: stray spell row end", path, line.Number)
			}

			fields, err := splitCSV(data.String())

			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, start, err)
			}

			spell, err := parseDescriptor(path, start, fields)

			if err != nil {
				return nil, err
			}

			if spell.ID == "SPELL_NO_SPELL" {
				spell.Status = content.SpellSentinel
			}

			if _, duplicate := result[spell.ID]; duplicate {
				return nil, fmt.Errorf("%s:%d: duplicate spell %s", path, start, spell.ID)
			}

			result[spell.ID] = spell
			block = false
			continue
		}

		return nil, fmt.Errorf("%s:%d: unsupported spell table row %q", path, line.Number, value)
	}

	if block || !tableOpened || !closed || len(result) == 0 || axedCount > 0 && (!macro || !macroBody) {
		return nil, fmt.Errorf("%s: incomplete spell table", path)
	}

	return result, nil
}

func parseRemoved(path string, body []byte) (map[string]bool, error) {
	source := string(body)
	start := strings.Index(source, "const set<spell_type> removed_spells =")

	if start < 0 {
		return nil, fmt.Errorf("%s: missing removed spell set", path)
	}

	end := strings.Index(source[start:], "};")

	if end < 0 {
		return nil, fmt.Errorf("%s: unterminated removed spell set", path)
	}

	section := strings.Repeat("\n", strings.Count(source[:start], "\n")) + source[start:start+end+2]
	lines, err := sourceparse.Tag34NumberedLines(path, []byte(section))

	if err != nil {
		return nil, err
	}

	seen, inside, done := map[string]bool{}, false, false

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			if strings.Contains(value, "removed_spells =") {
				inside = true
			}

			continue
		}

		if value == "{" {
			continue
		}

		if value == "};" {
			done = true
			break
		}

		if value == "" {
			continue
		}

		id := strings.TrimSuffix(value, ",")

		if !spellID.MatchString(id) || seen[id] {
			return nil, fmt.Errorf("%s:%d: invalid or duplicate removed spell %q", path, line.Number, value)
		}

		seen[id] = true
	}

	if !done {
		return nil, fmt.Errorf("%s: incomplete removed spell set", path)
	}

	return seen, nil
}

func reconcile(ids []content.SpellDef, spells map[string]content.SpellDef, removed map[string]bool) error {
	for _, id := range ids {
		spell, exists := spells[id.ID]

		if !exists {
			return fmt.Errorf("missing descriptor for %s", id.ID)
		}

		if removed[id.ID] != (spell.Status == content.SpellRemoved) {
			return fmt.Errorf("removed status differs for %s", id.ID)
		}
	}

	if len(ids) != len(spells) {
		return fmt.Errorf("spell identity/descriptor count differs: %d/%d", len(ids), len(spells))
	}

	for id := range removed {
		if _, exists := spells[id]; !exists {
			return fmt.Errorf("removed spell %s has no descriptor", id)
		}
	}

	return nil
}
