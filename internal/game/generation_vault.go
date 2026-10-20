package game

import (
	"fmt"
	"sort"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

var implementedTerrainAliases = map[string]bool{
	"DNGN_RUNED_DOOR":            true,
	"DNGN_STONE_STAIRS_UP_II":    true,
	"DNGN_STONE_STAIRS_UP_III":   true,
	"DNGN_STONE_STAIRS_DOWN_II":  true,
	"DNGN_STONE_STAIRS_DOWN_III": true,
	"DNGN_ESCAPE_HATCH_UP":       true,
	"DNGN_ESCAPE_HATCH_DOWN":     true,
}

func loadLuaVault(level *Level, generated map[string]any) error {
	if raw, present := generated["vault_ids"]; present {
		values, err := luaScenarioList(raw, "vault IDs")

		if err != nil {
			return fmt.Errorf("Lua level %d: %w", level.ID, err)
		}

		ids := make([]string, 0, len(values))

		for _, value := range values {
			id, ok := value.(string)

			if !ok {
				return fmt.Errorf("Lua level %d has a nonstring vault ID", level.ID)
			}

			ids = append(ids, id)
		}

		if err := level.SetVaultIDs(ids); err != nil {
			return err
		}
	}

	id, hasID := generated["vault_id"].(string)

	if !hasID {
		if generated["vault_records"] != nil {
			return fmt.Errorf("Lua level %d has vault records without an identity", level.ID)
		}

		return nil
	}

	if err := level.SetVaultID(id); err != nil {
		return err
	}

	entries, ok := generated["vault_records"].([]any)

	if !ok {
		if empty, isMap := generated["vault_records"].(map[string]any); isMap &&
			len(empty) == 0 {
			entries = []any{}
		} else {
			return fmt.Errorf("Lua level %d has no vault record list", level.ID)
		}
	}

	for index, value := range entries {
		record, err := luaVaultRecord(value)

		if err != nil {
			return fmt.Errorf("Lua level %d vault record %d: %w", level.ID, index, err)
		}

		if err := level.AddVaultRecord(record); err != nil {
			return err
		}
	}

	return nil
}

func luaVaultRecord(value any) (vault.Record, error) {
	fields, ok := value.(map[string]any)

	if !ok {
		return vault.Record{}, fmt.Errorf("record is not a table")
	}

	kind, _ := fields["kind"].(string)
	sourceID, _ := fields["vault_id"].(string)
	identity, _ := fields["identity"].(string)
	sourceGlyph, _ := fields["source"].(string)
	directive, _ := fields["directive"].(string)
	method, _ := fields["method"].(string)
	pending, hasPending := fields["pending"].(bool)
	overridden, _ := fields["overridden"].(bool)
	x, err := decisionInteger(fields, "x")

	if err != nil {
		return vault.Record{}, err
	}

	y, err := decisionInteger(fields, "y")

	if err != nil {
		return vault.Record{}, err
	}

	line, _ := optionalDecisionInteger(fields, "line")

	if !hasPending {
		pending = kind != string(vault.KindSourceFeature)
	}

	record := vault.Record{
		Kind:           vault.Kind(kind),
		SourceID:       sourceID,
		Identity:       identity,
		SourceGlyph:    sourceGlyph,
		Directive:      directive,
		ActivationHook: method,

		X:          x,
		Y:          y,
		Line:       line,
		Pending:    pending,
		Overridden: overridden,
	}

	if kind == string(vault.KindSourceFeature) &&
		!terrain.Valid(terrain.ID(identity)) &&
		!implementedTerrainAliases[identity] && !overridden {
		record.Pending = true
	}

	if targets, hasTargets := fields["targets"].(string); hasTargets {
		record.Arguments = append(record.Arguments, vault.Argument{
			Name:   "targets",
			Kind:   vault.ValueString,
			String: targets,
		})
	}

	if mode, hasMode := fields["assignment_mode"].(string); hasMode {
		record.Arguments = append(record.Arguments, vault.Argument{
			Name:   "assignment_mode",
			Kind:   vault.ValueString,
			String: mode,
		})
	}

	arguments, ok := fields["arguments"].(map[string]any)

	if fields["arguments"] != nil && !ok {
		return vault.Record{}, fmt.Errorf("arguments are not a named table")
	}

	keys := make([]string, 0, len(arguments))

	for name := range arguments {
		keys = append(keys, name)
	}

	sort.Strings(keys)

	for _, name := range keys {
		argument, err := luaVaultArgument(name, arguments[name])

		if err != nil {
			return vault.Record{}, err
		}

		record.Arguments = append(record.Arguments, argument)
	}

	if record.Pending &&
		(record.Kind == vault.KindFeature ||
			record.Kind == vault.KindSourceFeature) {
		record.Arguments = append(record.Arguments, vault.Argument{
			Name: "pending_reason",
			Kind: vault.ValueString,
			String: fmt.Sprintf(
				"feature %q has no active gameplay effect", record.Identity),
		})
	}

	return record, nil
}

func luaVaultArgument(name string, value any) (vault.Argument, error) {
	argument := vault.Argument{
		Name: name,
	}

	switch typed := value.(type) {
	case bool:
		argument.Kind = vault.ValueBool
		argument.Bool = typed

	case int64:
		argument.Kind = vault.ValueInt
		argument.Int = typed

	case string:
		argument.Kind = vault.ValueString
		argument.String = typed

	default:
		return vault.Argument{}, fmt.Errorf("argument %s has unsupported type %T", name, value)
	}

	return argument, nil
}
