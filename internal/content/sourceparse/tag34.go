// Package sourceparse contains the narrow TAG_MAJOR_VERSION=34 scanner shared
// by developer-run content importers. It does not parse general C++.
package sourceparse

import (
	"fmt"
	"regexp"
	"strings"
)

var blockComment = regexp.MustCompile(`(?s)/\*.*?\*/`)
var enumEntry = regexp.MustCompile(`^([A-Z][A-Z0-9_]*)\s*(=\s*[^,]+)?\s*,?`)

type tagBranch struct {
	parent   bool
	matched  bool
	elseSeen bool
}

func tag34Condition(directive string) (bool, bool) {
	switch directive {
	case "TAG_MAJOR_VERSION == 34":
		return true, true
	case "TAG_MAJOR_VERSION > 34":
		return false, true
	default:
		return false, false
	}
}

// Tag34Lines resolves only the conditional forms present in the pinned source.
func Tag34Lines(path string, data []byte) ([]string, error) {
	clean := blockComment.ReplaceAllString(string(data), "")
	lines := strings.Split(clean, "\n")
	active := true
	var stack []tagBranch
	var result []string
	for n, line := range lines {
		trimmed := strings.TrimSpace(line)
		switch {
		case strings.HasPrefix(trimmed, "#if "):
			condition, supported := tag34Condition(strings.TrimPrefix(trimmed, "#if "))
			if !supported {
				return nil, fmt.Errorf("%s:%d: unsupported conditional %s", path, n+1, trimmed)
			}
			stack = append(stack, tagBranch{parent: active, matched: condition})
			active = active && condition
		case strings.HasPrefix(trimmed, "#elif "):
			if len(stack) == 0 || stack[len(stack)-1].elseSeen {
				return nil, fmt.Errorf("%s:%d: unexpected #elif", path, n+1)
			}
			condition, supported := tag34Condition(strings.TrimPrefix(trimmed, "#elif "))
			if !supported {
				return nil, fmt.Errorf("%s:%d: unsupported conditional %s", path, n+1, trimmed)
			}
			top := &stack[len(stack)-1]
			active = top.parent && !top.matched && condition
			top.matched = top.matched || condition
		case trimmed == "#else":
			if len(stack) == 0 || stack[len(stack)-1].elseSeen {
				return nil, fmt.Errorf("%s:%d: unexpected #else", path, n+1)
			}
			top := &stack[len(stack)-1]
			top.elseSeen = true
			active = top.parent && !top.matched
			top.matched = true
		case trimmed == "#endif":
			if len(stack) == 0 {
				return nil, fmt.Errorf("%s:%d: unexpected #endif", path, n+1)
			}
			active = stack[len(stack)-1].parent
			stack = stack[:len(stack)-1]
		case strings.HasPrefix(trimmed, "#if") || strings.HasPrefix(trimmed, "#elif") || strings.HasPrefix(trimmed, "#ifdef") || strings.HasPrefix(trimmed, "#ifndef"):
			return nil, fmt.Errorf("%s:%d: unsupported conditional %s", path, n+1, trimmed)
		default:
			if active {
				result = append(result, strings.SplitN(line, "//", 2)[0])
			}
		}
	}
	if len(stack) != 0 {
		return nil, fmt.Errorf("%s: unterminated conditional", path)
	}
	return result, nil
}

// ActiveEnumIDs reports concrete active enum members, excluding aliases.
func ActiveEnumIDs(path string, data []byte, prefix string) (map[string]struct{}, error) {
	lines, err := Tag34Lines(path, data)
	if err != nil {
		return nil, err
	}
	ids := map[string]struct{}{}
	inside, started := false, false
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "enum ") {
			started = true
			if strings.Contains(trimmed, "{") {
				inside = true
			}
			continue
		}
		if started && !inside {
			if strings.Contains(trimmed, "{") {
				inside = true
			}
			continue
		}
		if inside && strings.HasPrefix(trimmed, "}") {
			break
		}
		if !inside {
			continue
		}
		match := enumEntry.FindStringSubmatch(trimmed)
		if match == nil || !strings.HasPrefix(match[1], prefix) || match[2] != "" {
			continue
		}
		if _, exists := ids[match[1]]; exists {
			return nil, fmt.Errorf("%s: duplicate enum ID %s", path, match[1])
		}
		ids[match[1]] = struct{}{}
	}
	if !started || !inside || len(ids) == 0 {
		return nil, fmt.Errorf("%s: no active %s enum entries", path, prefix)
	}
	return ids, nil
}
