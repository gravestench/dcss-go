package vault

import (
	"regexp"
	"strings"
)

var propsMarkerString = regexp.MustCompile(`([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"([^"]*)"`)

// MarkerProperty reads retained DES props_marker data without evaluating its Lua.
// Typed arguments also support markers placed directly by a generation hook.
func (r Record) MarkerProperty(key string) (string, bool) {
	if r.Kind != KindMarker || r.Overridden {
		return "", false
	}

	for _, argument := range r.Arguments {
		if argument.Name == key && argument.Kind == ValueString {
			return argument.String, true
		}
	}

	identity := strings.TrimSpace(r.Identity)

	if !strings.HasPrefix(identity, "lua:props_marker") {
		return "", false
	}

	for _, match := range propsMarkerString.FindAllStringSubmatch(identity, -1) {
		if match[1] == key {
			return match[2], true
		}
	}

	return "", false
}
