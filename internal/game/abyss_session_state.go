package game

import (
	"encoding/json"
	"fmt"

	"crawl/internal/save"
	"crawl/internal/script"
)

const abyssSessionStateName = "abyss"

// The game owns the saved representation, while Lua owns every decision
// that creates or changes it. JSON converts the already validated record
// to detached plain fields for the generic Lua session API.
func (g *Game) abyssSessionStateHost() script.SessionStateHost {
	return script.SessionStateHost{
		Read: func() (map[string]any, error) {
			if g.abyssState == nil {
				return nil, nil
			}

			encoded, err := json.Marshal(g.abyssState)

			if err != nil {
				return nil, fmt.Errorf("encode Abyss state: %w", err)
			}

			var values map[string]any

			if err := json.Unmarshal(encoded, &values); err != nil {
				return nil, fmt.Errorf("decode Abyss state fields: %w", err)
			}

			return values, nil
		},
		Prepare: func(values map[string]any) (script.SessionChange, error) {
			encoded, err := json.Marshal(abyssListFields(values))

			if err != nil {
				return script.SessionChange{},
					fmt.Errorf("encode Abyss candidate: %w", err)
			}

			var candidate save.AbyssStateRecord

			if err := json.Unmarshal(encoded, &candidate); err != nil {
				return script.SessionChange{},
					fmt.Errorf("decode Abyss candidate: %w", err)
			}

			if err := save.ValidateAbyssState(&candidate); err != nil {
				return script.SessionChange{}, err
			}

			previous := cloneAbyssState(g.abyssState)

			return script.SessionChange{
				Apply: func() error {
					return g.acceptAbyssState(&candidate)
				},
				Undo: func() error {
					g.abyssState = cloneAbyssState(previous)

					return nil
				},
			}, nil
		},
	}
}

// An empty Lua table carries no array/map distinction across policyValues.
// These three saved fields are lists by schema, so normalize only their
// empty form before JSON performs the typed record validation.
func abyssListFields(values map[string]any) map[string]any {
	normalized := make(map[string]any, len(values))

	for key, value := range values {
		normalized[key] = value
	}

	for _, name := range []string{
		"sample_queue",
		"selected_map_ids",
		"transit",
	} {
		if empty, okay := normalized[name].(map[string]any); okay &&
			len(empty) == 0 {
			normalized[name] = []any{}
		}
	}

	return normalized
}
