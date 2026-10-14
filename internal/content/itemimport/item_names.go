package itemimport

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

type sourceName struct {
	text string
	line int
}

var directCaseName = regexp.MustCompile(`case\s+([A-Z][A-Z0-9_]*)\s*:\s*return\s+"((?:\\.|[^"\\])*)"\s*;`)

func sourceNameView(path string, data []byte) (sourceView, error) {
	// The needed naming functions precede unrelated tile-only conditionals.
	cut := strings.Index(string(data), "#ifdef USE_TILE_WEB")

	if cut >= 0 {
		data = data[:cut]
	}

	return newSourceView(path, data)
}

func functionBody(view sourceView, marker string) (string, int, error) {
	start := strings.Index(view.text, marker+"(")

	if start < 0 {
		return "", 0, fmt.Errorf("%s: missing %s", view.path, marker)
	}

	open := strings.Index(view.text[start:], "{")

	if open < 0 {
		return "", 0, fmt.Errorf("%s:%d: %s lacks body", view.path, view.line(start), marker)
	}

	open += start
	body, _, err := balancedPart(view.text, open, '{', '}')

	if err != nil {
		return "", 0, fmt.Errorf("%s:%d: %s: %w", view.path, view.line(open), marker, err)
	}

	return body, open + 1, nil
}

func caseNames(view sourceView, body string, offset int) (map[string]sourceName, error) {
	names := map[string]sourceName{}

	for _, match := range directCaseName.FindAllStringSubmatchIndex(body, -1) {
		id := body[match[2]:match[3]]
		value, err := strconv.Unquote(`"` + body[match[4]:match[5]] + `"`)

		if err != nil {
			return nil, fmt.Errorf("%s:%d: invalid name for %s: %w", view.path, view.line(offset+match[0]), id, err)
		}

		if _, found := names[id]; found {
			return nil, fmt.Errorf("%s:%d: ambiguous name for %s", view.path, view.line(offset+match[0]), id)
		}

		names[id] = sourceName{
			text: value,
			line: view.line(offset + match[0]),
		}
	}

	return names, nil
}

func functionCaseNames(view sourceView, marker string) (map[string]sourceName, error) {
	body, offset, err := functionBody(view, marker)

	if err != nil {
		return nil, err
	}

	return caseNames(view, body, offset)
}

func sourceLineFor(view sourceView, text string) (int, error) {
	where := strings.Index(view.text, text)

	if where < 0 {
		return 0, fmt.Errorf("%s: missing naming case %q", view.path, text)
	}

	return view.line(where), nil
}
