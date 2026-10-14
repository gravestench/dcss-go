package game

import (
	"encoding/json"
	"fmt"
	"slices"

	"dcrawl-go/internal/modfs"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

const luaDialect = "gopher-lua-5.1"

func (g *Game) savedLuaSchemas() []save.LuaSchemaRecord {
	stores := akara.DynamicStores(g.world)
	records := make([]save.LuaSchemaRecord, 0, len(stores))

	for _, store := range stores {
		schema := store.Schema()

		records = append(records, save.LuaSchemaRecord{
			Name:    schema.Name,
			Version: schema.Version,
		})
	}

	return records
}

// Akara's live references cannot become stale during this serial snapshot.
// Encoding a registered primitive field is likewise an internal invariant.
func (g *Game) savedLuaComponents(entity akara.Entity) []save.DynamicComponentRecord {
	var records []save.DynamicComponentRecord

	for _, store := range akara.DynamicStores(g.world) {
		component, found := store.Get(entity)

		if !found {
			continue
		}

		values, err := component.Snapshot()

		if err != nil {
			panic(fmt.Sprintf("snapshot Lua component %s: %v", store.Schema().Name, err))
		}

		encoded := make(map[string]json.RawMessage, len(values))

		for name, value := range values {
			data, err := json.Marshal(value)

			if err != nil {
				panic(fmt.Sprintf("encode Lua component %s.%s: %v", store.Schema().Name, name, err))
			}

			encoded[name] = data
		}

		records = append(records, save.DynamicComponentRecord{
			Schema: store.Schema().Name,
			Values: encoded,
		})
	}

	return records
}

func (g *Game) validateSavedLuaSchemas(
	records []save.LuaSchemaRecord,
	allowNewSchemas bool,
) error {
	registered := akara.DynamicStores(g.world)

	if !allowNewSchemas && len(records) != len(registered) {
		return fmt.Errorf("Lua component schema count differs from current ruleset")
	}

	current := make(map[string]uint32, len(registered))

	for _, store := range registered {
		schema := store.Schema()

		current[schema.Name] = schema.Version
	}

	seen := make(map[string]bool, len(records))

	for _, record := range records {
		if seen[record.Name] {
			return fmt.Errorf("saved Lua schema %s is duplicated", record.Name)
		}

		seen[record.Name] = true

		version, found := current[record.Name]

		if !found || version != record.Version {
			return fmt.Errorf("Lua schema %s differs from current ruleset", record.Name)
		}
	}

	return nil
}

func (g *Game) restoreLuaComponents(records []save.EntityRecord) error {
	entities := g.world.Entities()
	known := make(map[akara.Entity]bool, len(entities))

	for _, entity := range entities {
		known[entity] = true
	}

	for _, record := range records {
		entity := akara.Entity(record.ID)
		seen := make(map[string]bool, len(record.Dynamic))

		for _, component := range record.Dynamic {
			if seen[component.Schema] {
				return fmt.Errorf("entity %d repeats Lua component %s", entity, component.Schema)
			}

			seen[component.Schema] = true

			store, found := akara.GetDynamicStore(g.world, component.Schema)

			if !found {
				return fmt.Errorf("entity %d has unknown Lua component %s", entity, component.Schema)
			}

			values, err := decodeLuaValues(store.Schema(), component.Values, known)

			if err != nil {
				return fmt.Errorf("entity %d Lua component %s: %w", entity, component.Schema, err)
			}

			if _, err := store.Set(entity, values); err != nil {
				return fmt.Errorf("restore entity %d Lua component %s: %w", entity, component.Schema, err)
			}
		}
	}

	return nil
}

func decodeLuaValues(
	schema akara.Schema,
	values map[string]json.RawMessage,
	known map[akara.Entity]bool,
) (map[string]any, error) {
	fields := make(map[string]akara.FieldKind, len(schema.Fields))

	for _, field := range schema.Fields {
		fields[field.Name] = field.Kind
	}

	if len(values) != len(fields) {
		return nil, fmt.Errorf("field count differs from schema")
	}

	decoded := make(map[string]any, len(values))

	for name, raw := range values {
		kind, found := fields[name]

		if !found {
			return nil, fmt.Errorf("unknown field %s", name)
		}

		value, err := decodeLuaField(kind, raw, known)

		if err != nil {
			return nil, fmt.Errorf("field %s: %w", name, err)
		}

		decoded[name] = value
	}

	return decoded, nil
}

func decodeLuaField(
	kind akara.FieldKind,
	raw json.RawMessage,
	known map[akara.Entity]bool,
) (any, error) {
	if string(raw) == "null" {
		return nil, fmt.Errorf("null is not a valid component field")
	}

	switch kind {
	case akara.FieldBool:
		var value bool
		err := json.Unmarshal(raw, &value)

		return value, err

	case akara.FieldInt64:
		var value int64
		err := json.Unmarshal(raw, &value)

		return value, err

	case akara.FieldUint64:
		var value uint64
		err := json.Unmarshal(raw, &value)

		return value, err

	case akara.FieldFloat64:
		var value float64
		err := json.Unmarshal(raw, &value)

		return value, err

	case akara.FieldString:
		var value string
		err := json.Unmarshal(raw, &value)

		return value, err

	case akara.FieldEntity:
		var id uint64

		if err := json.Unmarshal(raw, &id); err != nil {
			return nil, err
		}

		entity := akara.Entity(id)

		if entity != 0 && !known[entity] {
			return nil, fmt.Errorf("references missing entity %d", id)
		}

		return entity, nil

	default:
		return nil, fmt.Errorf("unsupported Lua field kind %d", kind)
	}
}

func (g *Game) savedRulesetFiles() []save.RulesetFile {
	manifest := g.rules.Manifest()
	records := make([]save.RulesetFile, 0, len(manifest))

	for _, file := range manifest {
		records = append(records, save.RulesetFile{
			Path:   file.Path,
			SHA256: file.SHA256,
		})
	}

	return records
}

func currentRulesetFiles(rules modfs.Ruleset) []save.RulesetFile {
	manifest := rules.Manifest()
	records := make([]save.RulesetFile, 0, len(manifest))

	for _, file := range manifest {
		records = append(records, save.RulesetFile{
			Path:   file.Path,
			SHA256: file.SHA256,
		})
	}

	return records
}

func rulesetFilesEqual(saved []save.RulesetFile, current []save.RulesetFile) bool {
	return slices.Equal(saved, current)
}

func changedRulesetPaths(saved, current []save.RulesetFile) []string {
	old := make(map[string]string, len(saved))
	new := make(map[string]string, len(current))

	for _, file := range saved {
		old[file.Path] = file.SHA256
	}

	for _, file := range current {
		new[file.Path] = file.SHA256
	}

	changes := make([]string, 0)

	for path, sum := range old {
		if new[path] != sum {
			changes = append(changes, path)
		}
	}

	for path := range new {
		if _, found := old[path]; !found {
			changes = append(changes, path)
		}
	}

	slices.Sort(changes)

	return changes
}
