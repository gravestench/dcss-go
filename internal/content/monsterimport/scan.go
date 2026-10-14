package monsterimport

import (
	"fmt"
	"strings"
)

type sourceRow struct {
	ID          string
	Line        int
	Fields      []string
	Removed     bool
	RemovedName string
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
