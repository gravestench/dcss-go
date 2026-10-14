package branchimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"unicode"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/content/sourceparse"
)

var enumRow = regexp.MustCompile(`^([A-Z][A-Z0-9_]*)(?:\s*=\s*([A-Z][A-Z0-9_]*|[0-9]+))?,?$`)
var dieSizeExpr = regexp.MustCompile(`^(?:[A-Z][A-Z0-9_]*|[0-9]+)$`)

func parseEnum(path string, body []byte) ([]content.BranchDef, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	var inside bool
	var opened bool
	var countSeen bool
	var closed bool

	var result []content.BranchDef
	seen := map[string]bool{}

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			if strings.HasPrefix(value, "enum branch_type") {
				inside = true
				opened = strings.Contains(value, "{")
			}

			continue
		}

		if value == "" {
			continue
		}

		if !opened {
			if value != "{" {
				return nil, fmt.Errorf("%s:%d: missing branch enum opening brace", path, line.Number)
			}

			opened = true
			continue
		}

		if value == "};" {
			closed = true
			break
		}

		match := enumRow.FindStringSubmatch(value)

		if match == nil {
			return nil, fmt.Errorf("%s:%d: unsupported branch enum row %q", path, line.Number, value)
		}

		id, target := match[1], match[2]

		if id == "NUM_BRANCHES" {
			if target != "" || countSeen {
				return nil, fmt.Errorf("%s:%d: changed branch count sentinel", path, line.Number)
			}

			countSeen = true
			continue
		}

		if id == "GLOBAL_BRANCH_INFO" && countSeen && target == "127" {
			continue
		}

		if countSeen {
			return nil, fmt.Errorf("%s:%d: concrete branch follows NUM_BRANCHES", path, line.Number)
		}

		if target != "" {
			if !(strings.HasPrefix(id, "BRANCH_FIRST_") || strings.HasPrefix(id, "BRANCH_LAST_")) || !seen[target] {
				return nil, fmt.Errorf("%s:%d: unsupported branch alias %q", path, line.Number, value)
			}

			continue
		}

		if !strings.HasPrefix(id, "BRANCH_") || seen[id] {
			return nil, fmt.Errorf("%s:%d: invalid or duplicate branch ID %q", path, line.Number, id)
		}

		seen[id] = true
		result = append(result, content.BranchDef{
			ID:        id,
			NumericID: len(result),
			EnumLine:  line.Number,
		})
	}

	if !inside || !opened || !countSeen || !closed || len(result) == 0 {
		return nil, fmt.Errorf("%s: incomplete branch enum", path)
	}

	return result, nil
}

// splitFields separates a C++ aggregate at top-level commas; rune lists and
// adjacent string literals remain single fields.
func splitFields(value string) ([]string, error) {
	var fields []string
	start, depth := 0, 0
	var quote byte
	escaped := false

	for i := 0; i < len(value); i++ {
		char := value[i]

		if quote != 0 {
			if escaped {
				escaped = false
			} else if char == '\\' {
				escaped = true
			} else if char == quote {
				quote = 0
			}

			continue
		}

		switch char {
		case '\'', '"':
			quote = char

		case '{':
			depth++

		case '}':
			depth--

			if depth < 0 {
				return nil, fmt.Errorf("unbalanced aggregate brace")
			}

		case ',':
			if depth == 0 {
				fields = append(fields, strings.TrimSpace(value[start:i]))
				start = i + 1
			}
		}
	}

	if quote != 0 || depth != 0 {
		return nil, fmt.Errorf("unterminated aggregate field")
	}

	if tail := strings.TrimSpace(value[start:]); tail != "" {
		fields = append(fields, tail)
	}

	for _, field := range fields {
		if field == "" {
			return nil, fmt.Errorf("empty aggregate field")
		}
	}

	return fields, nil
}

func literalStrings(value string) (string, error) {
	if value == "nullptr" {
		return "", nil
	}

	var result strings.Builder

	for i := 0; i < len(value); {
		if unicode.IsSpace(rune(value[i])) {
			i++
			continue
		}

		if value[i] != '"' {
			return "", fmt.Errorf("unexpected string field %q", value)
		}

		start := i
		i++
		escaped := false

		for i < len(value) {
			if escaped {
				escaped = false
			} else if value[i] == '\\' {
				escaped = true
			} else if value[i] == '"' {
				i++
				break
			}

			i++
		}

		if i > len(value) || value[i-1] != '"' {
			return "", fmt.Errorf("unterminated string field %q", value)
		}

		part, err := strconv.Unquote(value[start:i])

		if err != nil {
			return "", err
		}

		result.WriteString(part)
	}

	return result.String(), nil
}

func prefixedList(value, prefix string) ([]string, error) {
	parts := strings.Split(value, "|")
	result := make([]string, 0, len(parts))

	for _, part := range parts {
		part = strings.TrimSpace(part)

		if !strings.HasPrefix(part, prefix) || len(part) == len(prefix) {
			return nil, fmt.Errorf("invalid %s token %q", prefix, part)
		}

		result = append(result, strings.TrimPrefix(part, prefix))
	}

	return result, nil
}

func parseRow(path string, line int, value string) (content.BranchDef, error) {
	fields, err := splitFields(strings.TrimSpace(value))

	if err != nil {
		return content.BranchDef{}, fmt.Errorf("%s:%d: %w", path, line, err)
	}

	if len(fields) != 19 && len(fields) != 20 {
		return content.BranchDef{}, fmt.Errorf("%s:%d: branch row has %d fields", path, line, len(fields))
	}

	b := content.BranchDef{
		ID:            fields[0],
		ParentID:      fields[1],
		SourceLine:    line,
		EntryFeature:  fields[7],
		ExitFeature:   fields[8],
		EscapeFeature: fields[9],
		FloorColor:    fields[14],
		RockColor:     fields[15],
		AmbientNoise:  fields[18],
	}

	for i, dest := range []*int{
		&b.MinDepth,
		&b.MaxDepth,
		&b.Depth,
		&b.AbsoluteDepth,
	} {
		*dest, err = strconv.Atoi(fields[i+2])

		if err != nil {
			return content.BranchDef{}, fmt.Errorf("%s:%d: invalid branch depth %q: %w", path, line, fields[i+2], err)
		}
	}

	b.Flags, err = prefixedList(fields[6], "brflag::")

	if err != nil {
		return content.BranchDef{}, fmt.Errorf("%s:%d: %w", path, line, err)
	}

	for i, dest := range []*string{
		&b.ShortName,
		&b.LongName,
		&b.Abbreviation,
		&b.EntryMessage,
	} {
		*dest, err = literalStrings(fields[i+10])

		if err != nil {
			return content.BranchDef{}, fmt.Errorf("%s:%d: %w", path, line, err)
		}
	}

	b.TravelShortcut, err = strconv.Unquote(fields[16])

	if err != nil {
		return content.BranchDef{}, fmt.Errorf("%s:%d: invalid branch shortcut: %w", path, line, err)
	}

	runeField := strings.TrimSpace(fields[17])

	if !strings.HasPrefix(runeField, "{") || !strings.HasSuffix(runeField, "}") {
		return content.BranchDef{}, fmt.Errorf("%s:%d: malformed rune list", path, line)
	}

	for _, runeID := range strings.Split(strings.TrimSpace(runeField[1:len(runeField)-1]), ",") {
		if runeID = strings.TrimSpace(runeID); runeID != "" {
			b.Runes = append(b.Runes, runeID)
		}
	}

	if len(fields) == 20 {
		b.MonDieSizeExpr = fields[19]

		if !dieSizeExpr.MatchString(b.MonDieSizeExpr) {
			return content.BranchDef{}, fmt.Errorf("%s:%d: unsupported monster death size %q", path, line, b.MonDieSizeExpr)
		}
	}

	if !strings.HasPrefix(b.AmbientNoise, "branch_noise::") {
		return content.BranchDef{}, fmt.Errorf("%s:%d: invalid ambient noise %q", path, line, b.AmbientNoise)
	}

	b.AmbientNoise = strings.TrimPrefix(b.AmbientNoise, "branch_noise::")

	if !strings.HasPrefix(b.ID, "BRANCH_") || (b.ParentID != "NUM_BRANCHES" && !strings.HasPrefix(b.ParentID, "BRANCH_")) {
		return content.BranchDef{}, fmt.Errorf("%s:%d: invalid branch identity or parent", path, line)
	}

	return b, nil
}

func braceDelta(value string) (int, error) {
	delta := 0
	var quote byte
	escaped := false

	for i := 0; i < len(value); i++ {
		char := value[i]

		if quote != 0 {
			if escaped {
				escaped = false
			} else if char == '\\' {
				escaped = true
			} else if char == quote {
				quote = 0
			}

			continue
		}

		switch char {
		case '\'', '"':
			quote = char

		case '{':
			delta++

		case '}':
			delta--
		}
	}

	if quote != 0 {
		return 0, fmt.Errorf("unterminated quoted literal")
	}

	return delta, nil
}

func parseTable(path string, body []byte) ([]content.BranchDef, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, body)

	if err != nil {
		return nil, err
	}

	var inside bool
	var opened bool
	var closed bool
	var rowOpen bool

	var rows []content.BranchDef
	var row strings.Builder
	depth := 0
	rowLine := 0

	for _, line := range lines {
		value := strings.TrimSpace(line.Text)

		if !inside {
			if strings.Contains(value, "branches[NUM_BRANCHES]") {
				inside = true
				opened = strings.HasSuffix(value, "{")
			}

			continue
		}

		if value == "" {
			continue
		}

		if !opened {
			if value != "{" {
				return nil, fmt.Errorf("%s:%d: missing branch table opening brace", path, line.Number)
			}

			opened = true
			continue
		}

		if !rowOpen && value == "};" {
			closed = true
			break
		}

		if !rowOpen {
			if !strings.HasPrefix(value, "{ BRANCH_") {
				return nil, fmt.Errorf("%s:%d: unsupported branch table row %q", path, line.Number, value)
			}

			rowOpen, rowLine = true, line.Number
			row.Reset()
		}

		if row.Len() > 0 {
			row.WriteByte(' ')
		}

		row.WriteString(value)
		change, err := braceDelta(value)

		if err != nil {
			return nil, fmt.Errorf("%s:%d: %w", path, line.Number, err)
		}

		depth += change

		if depth < 0 {
			return nil, fmt.Errorf("%s:%d: unbalanced branch row", path, line.Number)
		}

		if depth == 0 {
			text := strings.TrimSpace(row.String())

			if !strings.HasSuffix(text, "},") || !strings.HasPrefix(text, "{") {
				return nil, fmt.Errorf("%s:%d: malformed branch row ending", path, line.Number)
			}

			branch, err := parseRow(path, rowLine, strings.TrimSpace(text[1:len(text)-2]))

			if err != nil {
				return nil, err
			}

			rows = append(rows, branch)
			rowOpen = false
		}
	}

	if !inside || !opened || !closed || rowOpen || len(rows) == 0 {
		return nil, fmt.Errorf("%s: incomplete branch table", path)
	}

	return rows, nil
}

func reconcile(ids, rows []content.BranchDef) error {
	if len(ids) != len(rows) {
		return fmt.Errorf("branch enum/table count differs: %d/%d", len(ids), len(rows))
	}

	for i := range ids {
		if ids[i].ID != rows[i].ID {
			return fmt.Errorf("branch row %d is %s; expected %s", i, rows[i].ID, ids[i].ID)
		}
	}

	return nil
}
