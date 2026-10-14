package monsterimport

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"dcrawl-go/internal/content/sourceparse"
)

type sourceRow struct {
	ID          string
	Line        int
	Fields      []string
	Removed     bool
	RemovedName string
}

var monsterTable = regexp.MustCompile(`\bstatic\s+monsterentry\s+mondata\s*\[\s*\]\s*=`)

func parseRows(path string, data []byte) ([]sourceRow, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)
	if err != nil {
		return nil, err
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
					return nil, fmt.Errorf("%s:%d: unsupported table macro %s", path, line.Number, name)
				}
			} else {
				return nil, fmt.Errorf("%s:%d: unsupported directive %s", path, line.Number, trimmed)
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

	src := body.String()
	header := monsterTable.FindStringIndex(src)
	if header == nil {
		return nil, fmt.Errorf("%s: missing mondata table", path)
	}

	lineAt := func(pos int) int {
		idx := sort.Search(len(starts), func(i int) bool {
			return starts[i] > pos
		}) - 1
		if idx < 0 {
			return 0
		}

		return lines[idx].Number
	}
	pos := skipSpace(src, header[1])
	if pos >= len(src) || src[pos] != '{' {
		return nil, fmt.Errorf("%s:%d: missing mondata initializer", path, lineAt(pos))
	}

	pos++
	var rows []sourceRow
	for {
		pos = skipSpaceAndCommas(src, pos)
		if pos >= len(src) {
			return nil, fmt.Errorf("%s: unterminated mondata table", path)
		}

		if src[pos] == '}' {
			pos = skipSpace(src, pos+1)
			if pos >= len(src) || src[pos] != ';' {
				return nil, fmt.Errorf("%s:%d: missing table terminator", path, lineAt(pos))
			}

			return rows, nil
		}

		line := lineAt(pos)
		switch {
		case src[pos] == '{':
			inner, end, err := balanced(src, pos, '{', '}')
			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line, err)
			}

			fields, err := splitFields(inner)
			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line, err)
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
				return nil, fmt.Errorf("%s:%d: %s: monsterentry has %d fields, want 28", path, line, id, len(fields))
			}

			if !strings.HasPrefix(id, "MONS_") {
				return nil, fmt.Errorf("%s:%d: invalid monster ID %q", path, line, id)
			}

			rows = append(rows, sourceRow{
				ID:     id,
				Line:   line,
				Fields: fields,
			})
			pos = end
		case strings.HasPrefix(src[pos:], "AXED_MON("):
			inner, end, err := balanced(src, pos+len("AXED_MON"), '(', ')')
			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line, err)
			}

			fields, err := splitFields(inner)
			if err != nil || len(fields) != 2 {
				return nil, fmt.Errorf("%s:%d: malformed AXED_MON", path, line)
			}

			name, err := strconv.Unquote(fields[1])
			if err != nil || !strings.HasPrefix(fields[0], "MONS_") {
				return nil, fmt.Errorf("%s:%d: malformed AXED_MON identity", path, line)
			}

			rows = append(rows, sourceRow{
				ID:          fields[0],
				Line:        line,
				Removed:     true,
				RemovedName: name,
			})
			pos = end
		case strings.HasPrefix(src[pos:], "DUMMY("):
			inner, end, err := balanced(src, pos+len("DUMMY"), '(', ')')
			if err != nil {
				return nil, fmt.Errorf("%s:%d: %w", path, line, err)
			}

			fields, err := splitFields(inner)
			if err != nil || len(fields) != 5 || !strings.HasPrefix(fields[0], "MONS_") {
				return nil, fmt.Errorf("%s:%d: malformed DUMMY", path, line)
			}

			pos = end // DUMMY is an enum-only genus placeholder, not an explicit definition.
		default:
			return nil, fmt.Errorf("%s:%d: unsupported table token near %.32q", path, line, src[pos:])
		}
	}
}

func skipSpace(src string, pos int) int {
	for pos < len(src) && (src[pos] == ' ' || src[pos] == '\t' || src[pos] == '\r' || src[pos] == '\n') {
		pos++
	}

	return pos
}

func skipSpaceAndCommas(src string, pos int) int {
	for pos < len(src) && (src[pos] == ' ' || src[pos] == '\t' || src[pos] == '\r' ||
		src[pos] == '\n' || src[pos] == ',') {
		pos++
	}

	return pos
}

func balanced(src string, pos int, open, close byte) (string, int, error) {
	if pos >= len(src) || src[pos] != open {
		return "", 0, fmt.Errorf("missing %c", open)
	}

	depth, quote, escaped := 0, byte(0), false
	for i := pos; i < len(src); i++ {
		c := src[i]
		if quote != 0 {
			if escaped {
				escaped = false
			} else if c == '\\' {
				escaped = true
			} else if c == quote {
				quote = 0
			}

			continue
		}

		if c == '"' || c == '\'' {
			quote = c
			continue
		}

		if c == open {
			depth++
		} else if c == close {
			depth--
			if depth == 0 {
				return src[pos+1 : i], i + 1, nil
			}
		}
	}

	return "", 0, fmt.Errorf("unbalanced or unterminated %c initializer", open)
}

func splitFields(src string) ([]string, error) {
	var fields []string
	start, braces, parens := 0, 0, 0
	quote, escaped := byte(0), false
	for i := 0; i < len(src); i++ {
		c := src[i]
		if quote != 0 {
			if escaped {
				escaped = false
			} else if c == '\\' {
				escaped = true
			} else if c == quote {
				quote = 0
			}

			continue
		}

		switch c {
		case '"', '\'':
			quote = c
		case '{':
			braces++
		case '}':
			braces--
		case '(':
			parens++
		case ')':
			parens--
		case ',':
			if braces == 0 && parens == 0 {
				fields = append(fields, strings.TrimSpace(src[start:i]))
				start = i + 1
			}
		}

		if braces < 0 || parens < 0 {
			return nil, fmt.Errorf("unbalanced initializer field")
		}
	}

	if quote != 0 || braces != 0 || parens != 0 {
		return nil, fmt.Errorf("unterminated initializer field")
	}

	last := strings.TrimSpace(src[start:])
	if last != "" {
		fields = append(fields, last)
	}

	return fields, nil
}
