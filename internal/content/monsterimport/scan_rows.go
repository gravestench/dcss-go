package monsterimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content/sourceparse"
)

var monsterTable = regexp.MustCompile(`\bstatic\s+monsterentry\s+mondata\s*\[\s*\]\s*=`)

type monsterRowScanner struct {
	path   string
	source string
	starts []int
	lines  []sourceparse.Line
}

func parseRows(path string, data []byte) ([]sourceRow, error) {
	source, starts, lines, err := activeMonsterTable(path, data)

	if err != nil {
		return nil, err
	}

	scanner := monsterRowScanner{
		path:   path,
		source: source,
		starts: starts,
		lines:  lines,
	}

	return scanner.scanRows()
}

func activeMonsterTable(path string, data []byte) (string, []int, []sourceparse.Line, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)

	if err != nil {
		return "", nil, nil, err
	}

	var body strings.Builder
	starts := make([]int, len(lines))
	inTable := false

	for i := 0; i < len(lines); i++ {
		line := lines[i]
		starts[i] = body.Len()
		text := line.Text

		if strings.Contains(text, "static monsterentry mondata") {
			inTable = true
		}

		if strings.HasPrefix(strings.TrimSpace(text), "#") {
			// The two pinned table macros are expanded by the scanner/decoder,
			// not by a general preprocessor. Other directives in the table fail.
			trimmed := strings.TrimSpace(text)

			if !inTable {
				// Includes and helper macros before the table are not input rows.
			} else if strings.HasPrefix(trimmed, "#define ") {
				name := strings.Fields(trimmed)[1]

				if !strings.HasPrefix(name, "AXED_MON(") && !strings.HasPrefix(name, "DUMMY(") {
					return "", nil, nil, fmt.Errorf("%s:%d: unsupported table macro %s", path, line.Number, name)
				}
			} else {
				return "", nil, nil, fmt.Errorf("%s:%d: unsupported directive %s", path, line.Number, trimmed)
			}

			text = ""

			if strings.HasSuffix(strings.TrimSpace(line.Text), "\\") {
				for i+1 < len(lines) {
					i++
					starts[i] = body.Len() + len(text) + 1
					body.WriteString(text)
					body.WriteByte('\n')
					text = ""

					if !strings.HasSuffix(strings.TrimSpace(lines[i].Text), "\\") {
						break
					}
				}
			}
		}

		body.WriteString(text)
		body.WriteByte('\n')
	}

	return body.String(), starts, lines, nil
}

func (scanner monsterRowScanner) lineAt(pos int) int {
	idx := sort.Search(len(scanner.starts), func(i int) bool {
		return scanner.starts[i] > pos
	}) - 1

	if idx < 0 {
		return 0
	}

	return scanner.lines[idx].Number
}

func (scanner monsterRowScanner) scanRows() ([]sourceRow, error) {
	header := monsterTable.FindStringIndex(scanner.source)

	if header == nil {
		return nil, fmt.Errorf("%s: missing mondata table", scanner.path)
	}

	pos := skipSpace(scanner.source, header[1])

	if pos >= len(scanner.source) || scanner.source[pos] != '{' {
		return nil, fmt.Errorf("%s:%d: missing mondata initializer", scanner.path, scanner.lineAt(pos))
	}

	pos++
	var rows []sourceRow

	for {
		pos = skipSpaceAndCommas(scanner.source, pos)

		if pos >= len(scanner.source) {
			return nil, fmt.Errorf("%s: unterminated mondata table", scanner.path)
		}

		if scanner.source[pos] == '}' {
			pos = skipSpace(scanner.source, pos+1)

			if pos >= len(scanner.source) || scanner.source[pos] != ';' {
				return nil, fmt.Errorf("%s:%d: missing table terminator", scanner.path, scanner.lineAt(pos))
			}

			return rows, nil
		}

		row, include, next, err := scanner.scanRow(pos)

		if err != nil {
			return nil, err
		}

		if include {
			rows = append(rows, row)
		}

		pos = next
	}
}

func (scanner monsterRowScanner) scanRow(pos int) (sourceRow, bool, int, error) {
	line := scanner.lineAt(pos)
	src := scanner.source

	switch {
	case src[pos] == '{':
		row, next, err := scanner.aggregateRow(pos, line)

		return row, true, next, err

	case strings.HasPrefix(src[pos:], "AXED_MON("):
		row, next, err := scanner.removedRow(pos, line)

		return row, true, next, err

	case strings.HasPrefix(src[pos:], "DUMMY("):
		next, err := scanner.placeholderRow(pos, line)

		return sourceRow{}, false, next, err

	default:
		return sourceRow{}, false, 0, fmt.Errorf(
			"%s:%d: unsupported table token near %.32q",
			scanner.path,
			line,
			src[pos:],
		)
	}
}

func (scanner monsterRowScanner) aggregateRow(pos, line int) (sourceRow, int, error) {
	inner, end, err := balanced(scanner.source, pos, '{', '}')

	if err != nil {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: %w", scanner.path, line, err)
	}

	fields, err := splitFields(inner)

	if err != nil {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: %w", scanner.path, line, err)
	}

	id := ""

	if len(fields) > 0 {
		id = fields[0]
	}

	if len(fields) == 27 {
		// C++ aggregate initialization zeroes an omitted final corpse tile.
		fields = append(fields, "0")
	}

	if len(fields) != 28 {
		return sourceRow{}, 0, fmt.Errorf(
			"%s:%d: %s: monsterentry has %d fields, want 28",
			scanner.path,
			line,
			id,
			len(fields),
		)
	}

	if !strings.HasPrefix(id, "MONS_") {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: invalid monster ID %q", scanner.path, line, id)
	}

	row := sourceRow{
		ID:     id,
		Line:   line,
		Fields: fields,
	}

	return row, end, nil
}

func (scanner monsterRowScanner) removedRow(pos, line int) (sourceRow, int, error) {
	inner, end, err := balanced(scanner.source, pos+len("AXED_MON"), '(', ')')

	if err != nil {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: %w", scanner.path, line, err)
	}

	fields, err := splitFields(inner)

	if err != nil || len(fields) != 2 {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: malformed AXED_MON", scanner.path, line)
	}

	name, err := strconv.Unquote(fields[1])

	if err != nil || !strings.HasPrefix(fields[0], "MONS_") {
		return sourceRow{}, 0, fmt.Errorf("%s:%d: malformed AXED_MON identity", scanner.path, line)
	}

	row := sourceRow{
		ID:          fields[0],
		Line:        line,
		Removed:     true,
		RemovedName: name,
	}

	return row, end, nil
}

func (scanner monsterRowScanner) placeholderRow(pos, line int) (int, error) {
	inner, end, err := balanced(scanner.source, pos+len("DUMMY"), '(', ')')

	if err != nil {
		return 0, fmt.Errorf("%s:%d: %w", scanner.path, line, err)
	}

	fields, err := splitFields(inner)

	if err != nil || len(fields) != 5 || !strings.HasPrefix(fields[0], "MONS_") {
		return 0, fmt.Errorf("%s:%d: malformed DUMMY", scanner.path, line)
	}

	// DUMMY is an enum-only genus placeholder, not an explicit definition.
	return end, nil
}
