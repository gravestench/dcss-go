package game

import "fmt"

// SelectionRequest is a generic, no-time question from Lua game rules.
// The terminal displays these options and sends the chosen ID back.
type SelectionRequest struct {
	Kind    string
	Title   string
	Options []SelectionOption
}

type SelectionOption struct {
	ID    string
	Label string
}

func selectionFromDecision(value any) (*SelectionRequest, error) {
	fields, ok := value.(map[string]any)

	if !ok {
		return nil, fmt.Errorf("Lua selection is not a record")
	}

	kind, kindOK := fields["kind"].(string)
	title, titleOK := fields["title"].(string)

	if !kindOK ||
		!titleOK ||
		title == "" {
		return nil, fmt.Errorf("Lua selection lacks a kind or title")
	}

	switch kind {
	case "item", "spell", "cell", "offer", "card":

	default:
		return nil, fmt.Errorf("Lua selection has unknown kind %q", kind)
	}

	request := &SelectionRequest{
		Kind:  kind,
		Title: title,
	}

	if kind == "cell" {
		if _, found := fields["options"]; found {
			return nil, fmt.Errorf("cell selection cannot have options")
		}

		return request, nil
	}

	rows, ok := fields["options"].([]any)

	if !ok || len(rows) == 0 {
		return nil, fmt.Errorf("Lua selection has no options")
	}

	if len(rows) > 52 {
		return nil, fmt.Errorf("Lua selection exceeds 52 terminal letters")
	}

	seen := map[string]bool{}

	for index, row := range rows {
		option, ok := row.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("Lua selection option %d is not a record", index+1)
		}

		id, idOK := option["id"].(string)
		label, labelOK := option["label"].(string)

		if !idOK ||
			id == "" ||
			!labelOK ||
			label == "" ||
			seen[id] {
			return nil, fmt.Errorf("Lua selection option %d is invalid", index+1)
		}

		seen[id] = true
		request.Options = append(request.Options, SelectionOption{
			ID:    id,
			Label: label,
		})
	}

	return request, nil
}
