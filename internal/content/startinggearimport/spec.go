package startinggearimport

import (
	"fmt"
	"strconv"
	"strings"

	"dcrawl-go/internal/content"
)

// parseEquipmentSpec accepts only the suffix grammar used by pinned job data.
func parseEquipmentSpec(jobID, raw string) (string, content.StartingGrant, error) {
	grant := content.StartingGrant{
		Raw:      raw,
		Quantity: 1,
	}
	fail := func(reason string) (string, content.StartingGrant, error) {
		return "", content.StartingGrant{}, fmt.Errorf("job %s equipment %q: %s", jobID, raw, reason)
	}
	words := strings.Fields(raw)
	seen := map[string]bool{}

	for len(words) > 0 {
		token := words[len(words)-1]
		field, value, hasColon := strings.Cut(token, ":")

		if token == "no_exclude" {
			field = token
		} else if !hasColon {
			break
		}

		if seen[field] {
			return fail("duplicate tag " + field)
		}

		seen[field] = true

		switch field {
		case "q":
			n, err := strconv.Atoi(value)

			if err != nil || n <= 0 {
				return fail("invalid quantity " + token)
			}

			grant.Quantity = n

		case "plus":
			n, err := strconv.Atoi(value)

			if err != nil {
				return fail("invalid plus " + token)
			}

			grant.Plus = n

		case "charges":
			n, err := strconv.Atoi(value)

			if err != nil || n <= 0 {
				return fail("invalid charges " + token)
			}

			grant.Charges = n

		case "ego":
			if value == "" || strings.ContainsAny(value, ",: ") {
				return fail("invalid ego " + token)
			}

			grant.Ego = value

		case "no_exclude":
			if token != "no_exclude" {
				return fail("invalid no_exclude tag " + token)
			}

			grant.NoExclude = true

		default:
			return fail("unsupported tag " + token)
		}

		words = words[:len(words)-1]
	}

	if seen["plus"] && seen["charges"] {
		return fail("plus and charges cannot be combined")
	}

	if len(words) == 0 {
		return fail("missing item name")
	}

	for _, token := range words {
		if strings.Contains(token, ":") || token == "no_exclude" {
			return fail("tag appears inside item name")
		}
	}

	return strings.Join(words, " "), grant, nil
}
