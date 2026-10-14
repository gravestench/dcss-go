package itemimport

import (
	"fmt"
	"sort"
	"strings"

	"dcrawl-go/internal/content/sourceparse"
)

type sourceView struct {
	path   string
	text   string
	starts []int
	lines  []int
}

func newSourceView(path string, data []byte) (sourceView, error) {
	lines, err := sourceparse.Tag34NumberedLines(path, data)

	if err != nil {
		return sourceView{}, err
	}

	v := sourceView{path: path}
	var text strings.Builder

	for _, line := range lines {
		v.starts = append(v.starts, text.Len())
		v.lines = append(v.lines, line.Number)
		text.WriteString(line.Text)
		text.WriteByte('\n')
	}

	v.text = text.String()

	return v, nil
}

func (v sourceView) line(offset int) int {
	index := sort.Search(len(v.starts), func(i int) bool {
		return v.starts[i] > offset
	}) - 1

	if index < 0 {
		return 0
	}

	return v.lines[index]
}

func (v sourceView) initializer(marker string) (string, int, error) {
	start := strings.Index(v.text, marker)

	if start < 0 {
		return "", 0, fmt.Errorf("%s: missing %s", v.path, marker)
	}

	assign := strings.Index(v.text[start+len(marker):], "=")

	if assign < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks initializer", v.path, v.line(start), marker)
	}

	assign += start + len(marker)
	open := strings.Index(v.text[assign:], "{")

	if open < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks opening brace", v.path, v.line(start), marker)
	}

	open += assign
	inside, _, err := balancedPart(v.text, open, '{', '}')

	if err != nil {
		return "", 0, fmt.Errorf("%s:%d: %s: %w", v.path, v.line(open), marker, err)
	}

	return inside, open + 1, nil
}

// balancedPart and splitTopLevel preserve punctuation inside quoted strings.
func balancedPart(text string, start int, open, close byte) (string, int, error) {
	if start >= len(text) || text[start] != open {
		return "", 0, fmt.Errorf("expected %q", open)
	}

	depth := 0
	quote, escape := byte(0), false

	for i := start; i < len(text); i++ {
		c := text[i]

		if quote != 0 {
			if escape {
				escape = false
			} else if c == '\\' {
				escape = true
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
				return text[start+1 : i], i + 1, nil
			}
		}
	}

	return "", 0, fmt.Errorf("unterminated %q block", open)
}

type sourcePart struct {
	text  string
	start int
}

func splitTopLevel(text string, sep byte) ([]sourcePart, error) {
	start, braces, parens := 0, 0, 0
	quote, escape := byte(0), false
	var parts []sourcePart
	appendPart := func(end int) {
		part := text[start:end]
		trimmed := strings.TrimSpace(part)

		if trimmed != "" {
			parts = append(parts, sourcePart{
				text:  trimmed,
				start: start + strings.Index(part, trimmed),
			})
		}
	}

	for i := 0; i < len(text); i++ {
		c := text[i]

		if quote != 0 {
			if escape {
				escape = false
			} else if c == '\\' {
				escape = true
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

		default:
			if c == sep && braces == 0 && parens == 0 {
				appendPart(i)
				start = i + 1
			}
		}

		if braces < 0 || parens < 0 {
			return nil, fmt.Errorf("unbalanced source row")
		}
	}

	if quote != 0 || braces != 0 || parens != 0 {
		return nil, fmt.Errorf("unterminated source row")
	}

	appendPart(len(text))

	return parts, nil
}

func rowFields(raw string) ([]string, error) {
	if !strings.HasPrefix(raw, "{") {
		return nil, fmt.Errorf("expected braced row")
	}

	inside, end, err := balancedPart(raw, 0, '{', '}')

	if err != nil || strings.TrimSpace(raw[end:]) != "" {
		return nil, fmt.Errorf("malformed braced row")
	}

	parts, err := splitTopLevel(inside, ',')

	if err != nil {
		return nil, err
	}

	fields := make([]string, len(parts))

	for i, part := range parts {
		fields[i] = part.text
	}

	return fields, nil
}
