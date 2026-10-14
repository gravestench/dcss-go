package speciesimport

import (
	"bytes"
	"fmt"
	"io"
	"sort"
	"strings"

	"dcrawl-go/internal/content"
	"gopkg.in/yaml.v3"
)

type sourceSpecies struct {
	TagMajorVersion    int                           `yaml:"TAG_MAJOR_VERSION"`
	Enum               string                        `yaml:"enum"`
	Monster            string                        `yaml:"monster"`
	Name               string                        `yaml:"name"`
	ShortName          string                        `yaml:"short_name"`
	Adjective          string                        `yaml:"adjective"`
	Genus              string                        `yaml:"genus"`
	Difficulty         yaml.Node                     `yaml:"difficulty"`
	DifficultyPriority int                           `yaml:"difficulty_priority"`
	Aptitudes          map[string]yaml.Node          `yaml:"aptitudes"`
	SpeciesFlags       []string                      `yaml:"species_flags"`
	CanSwim            bool                          `yaml:"can_swim"`
	UndeadType         string                        `yaml:"undead_type"`
	Size               string                        `yaml:"size"`
	Strength           int                           `yaml:"str"`
	Intelligence       int                           `yaml:"int"`
	Dexterity          int                           `yaml:"dex"`
	LevelUpFrequency   int                           `yaml:"levelup_stat_frequency"`
	LevelUpStats       *[]string                     `yaml:"levelup_stats"`
	Mutations          map[int]map[string]int        `yaml:"mutations"`
	FakeMutations      []content.SpeciesFakeMutation `yaml:"fake_mutations"`
	RecommendedJobs    []string                      `yaml:"recommended_jobs"`
	RecommendedWeapons []string                      `yaml:"recommended_weapons"`
	WalkingVerb        string                        `yaml:"walking_verb"`
	AltarAction        string                        `yaml:"altar_action"`
	CreateEnum         bool                          `yaml:"create_enum"`
}

var ordinarySkills = []string{
	"fighting",
	"short_blades",
	"long_blades",
	"axes",
	"maces_and_flails",
	"polearms",
	"staves",
	"ranged weapons",
	"throwing",
	"armour",
	"dodging",
	"stealth",
	"shields",
	"unarmed_combat",
	"spellcasting",
	"conjurations",
	"hexes",
	"summoning",
	"necromancy",
	"transmutations",
	"translocations",
	"fire_magic",
	"ice_magic",
	"air_magic",
	"earth_magic",
	"poison_magic",
	"invocations",
	"evocations",
}

var allowedFlags = map[string]bool{
	"SPF_NO_HAIR":     true,
	"SPF_DRACONIAN":   true,
	"SPF_SMALL_TORSO": true,
	"SPF_NO_BONES":    true,
	"SPF_BARDING":     true,
}
var allowedSizes = map[string]bool{
	"tiny":   true,
	"little": true,
	"small":  true,
	"medium": true,
	"large":  true,
	"giant":  true,
}
var allowedUndead = map[string]bool{
	"US_ALIVE":       true,
	"US_UNDEAD":      true,
	"US_SEMI_UNDEAD": true,
}
var allowedStats = map[string]bool{
	"str": true,
	"int": true,
	"dex": true,
}
var allowedWeapons = map[string]bool{
	"SK_SHORT_BLADES":   true,
	"SK_LONG_BLADES":    true,
	"SK_AXES":           true,
	"SK_MACES_FLAILS":   true,
	"SK_POLEARMS":       true,
	"SK_STAVES":         true,
	"SK_RANGED_WEAPONS": true,
	"SK_UNARMED_COMBAT": true,
}

func skillID(name string) string {
	switch name {
	case "maces_and_flails":
		return "SK_MACES_FLAILS"
	case "ranged weapons":
		return "SK_RANGED_WEAPONS"
	case "summoning":
		return "SK_SUMMONINGS"
	default:
		return "SK_" + strings.ToUpper(name)
	}
}

func duplicateKeys(node *yaml.Node, path string) error {
	if node.Kind == yaml.MappingNode {
		seen := map[string]bool{}

		for i := 0; i < len(node.Content); i += 2 {
			key := node.Content[i].Value

			if seen[key] {
				return fmt.Errorf("%s: duplicate key %s", path, key)
			}

			seen[key] = true

			if err := duplicateKeys(node.Content[i+1], path+"."+key); err != nil {
				return err
			}
		}
	}

	for _, child := range node.Content {
		if node.Kind != yaml.MappingNode {
			if err := duplicateKeys(child, path); err != nil {
				return err
			}
		}
	}

	return nil
}

func scalar(path, field string, node *yaml.Node, tag string) error {
	if node.Kind != yaml.ScalarNode || node.Tag != tag {
		return fmt.Errorf("%s: %s must be %s", path, field, strings.TrimPrefix(tag, "!!"))
	}

	return nil
}

func sequence(path, field string, node *yaml.Node, elementTag string) error {
	if node.Kind != yaml.SequenceNode {
		return fmt.Errorf("%s: %s must be a sequence", path, field)
	}

	for _, element := range node.Content {
		if err := scalar(path, field, element, elementTag); err != nil {
			return err
		}
	}

	return nil
}

func validateSourceShape(path string, root *yaml.Node) error {
	if root.Kind != yaml.DocumentNode || len(root.Content) != 1 || root.Content[0].Kind != yaml.MappingNode {
		return fmt.Errorf("%s: species document must be a mapping", path)
	}

	fields := root.Content[0]
	seen := make(map[string]bool, len(fields.Content)/2)

	for i := 0; i < len(fields.Content); i += 2 {
		key, value := fields.Content[i], fields.Content[i+1]

		if err := scalar(path, "field name", key, "!!str"); err != nil {
			return err
		}

		name := key.Value
		seen[name] = true

		switch name {
		case "TAG_MAJOR_VERSION", "difficulty_priority", "str", "int", "dex", "levelup_stat_frequency":
			if err := scalar(path, name, value, "!!int"); err != nil {
				return err
			}
		case "enum", "monster", "name", "short_name", "adjective",
			"genus", "undead_type", "size", "walking_verb", "altar_action":
			if err := scalar(path, name, value, "!!str"); err != nil {
				return err
			}
		case "difficulty":
			if value.Kind != yaml.ScalarNode || (value.Tag != "!!str" && value.Tag != "!!bool") {
				return fmt.Errorf("%s: difficulty must be a string or False", path)
			}
		case "can_swim", "create_enum":
			if err := scalar(path, name, value, "!!bool"); err != nil {
				return err
			}
		case "species_flags", "levelup_stats", "recommended_jobs", "recommended_weapons":
			if err := sequence(path, name, value, "!!str"); err != nil {
				return err
			}
		case "aptitudes":
			if value.Kind != yaml.MappingNode {
				return fmt.Errorf("%s: aptitudes must be a mapping", path)
			}

			for j := 0; j < len(value.Content); j += 2 {
				aptName, aptValue := value.Content[j], value.Content[j+1]

				if err := scalar(path, "aptitudes key", aptName, "!!str"); err != nil {
					return err
				}

				if aptValue.Kind != yaml.ScalarNode || (aptValue.Tag != "!!int" && aptValue.Tag != "!!bool") {
					return fmt.Errorf("%s: aptitudes.%s must be an integer or False", path, aptName.Value)
				}
			}
		case "mutations":
			if value.Kind != yaml.MappingNode {
				return fmt.Errorf("%s: mutations must be a mapping", path)
			}

			for j := 0; j < len(value.Content); j += 2 {
				level, group := value.Content[j], value.Content[j+1]

				if err := scalar(path, "mutations level", level, "!!int"); err != nil {
					return err
				}

				if group.Kind != yaml.MappingNode {
					return fmt.Errorf("%s: mutations.%s must be a mapping", path, level.Value)
				}

				for k := 0; k < len(group.Content); k += 2 {
					mutation, amount := group.Content[k], group.Content[k+1]

					if err := scalar(path, "mutations key", mutation, "!!str"); err != nil {
						return err
					}

					if err := scalar(path, "mutations."+mutation.Value, amount, "!!int"); err != nil {
						return err
					}
				}
			}
		case "fake_mutations":
			if value.Kind != yaml.SequenceNode {
				return fmt.Errorf("%s: fake_mutations must be a sequence", path)
			}

			for _, entry := range value.Content {
				if entry.Kind != yaml.MappingNode {
					return fmt.Errorf("%s: fake_mutations entry must be a mapping", path)
				}

				for j := 0; j < len(entry.Content); j += 2 {
					part, text := entry.Content[j], entry.Content[j+1]

					if part.Value != "long" && part.Value != "short" {
						return fmt.Errorf("%s: fake_mutations has unknown field %s", path, part.Value)
					}

					if err := scalar(path, "fake_mutations."+part.Value, text, "!!str"); err != nil {
						return err
					}
				}
			}
		default:
			return fmt.Errorf("%s: unknown field %s", path, name)
		}
	}

	for _, name := range []string{
		"enum",
		"monster",
		"name",
		"difficulty",
		"aptitudes",
		"str",
		"int",
		"dex",
		"levelup_stat_frequency",
	} {
		if !seen[name] {
			return fmt.Errorf("%s: required field %s is missing", path, name)
		}
	}

	return nil
}

func yamlInt(path, field string, node yaml.Node, min, max int) (int, error) {
	var value any

	if err := node.Decode(&value); err != nil {
		return 0, fmt.Errorf("%s: %s: %w", path, field, err)
	}

	n, ok := value.(int)

	if !ok || n < min || n > max {
		return 0, fmt.Errorf("%s: %s must be integer in %d..%d", path, field, min, max)
	}

	return n, nil
}

func parseYAML(path string, data []byte) (content.SpeciesDef, int, error) {
	var tree yaml.Node

	if err := yaml.Unmarshal(data, &tree); err != nil {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: %w", path, err)
	}

	if err := duplicateKeys(&tree, path); err != nil {
		return content.SpeciesDef{}, 0, err
	}

	if err := validateSourceShape(path, &tree); err != nil {
		return content.SpeciesDef{}, 0, err
	}

	decoder := yaml.NewDecoder(bytes.NewReader(data))
	decoder.KnownFields(true)
	var source sourceSpecies

	if err := decoder.Decode(&source); err != nil {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: %w", path, err)
	}

	var trailing yaml.Node

	if err := decoder.Decode(&trailing); err != io.EOF {
		if err != nil {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: trailing document: %w", path, err)
		}

		return content.SpeciesDef{}, 0, fmt.Errorf("%s: multiple YAML documents are not supported", path)
	}

	if source.TagMajorVersion != 0 && source.TagMajorVersion != 34 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: TAG_MAJOR_VERSION %d is unsupported", path, source.TagMajorVersion)
	}

	if source.Name == "" || source.Enum == "" || source.Monster == "" {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: enum, monster, and name are required", path)
	}

	if source.ShortName == "" {
		if len(source.Name) < 2 {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: name too short for short_name", path)
		}

		source.ShortName = source.Name[:2]
	}

	if source.Strength < 1 || source.Strength > 100 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: str out of range", path)
	}

	if source.Intelligence < 1 || source.Intelligence > 100 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: int out of range", path)
	}

	if source.Dexterity < 1 || source.Dexterity > 100 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: dex out of range", path)
	}

	if source.LevelUpFrequency < 0 || source.LevelUpFrequency > 28 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: levelup_stat_frequency out of range", path)
	}

	if source.DifficultyPriority < 0 || source.DifficultyPriority > 1000 {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: difficulty_priority out of range", path)
	}

	var difficulty any

	if err := source.Difficulty.Decode(&difficulty); err != nil {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: difficulty: %w", path, err)
	}

	selectable := true
	difficultyName, ok := difficulty.(string)

	if !ok {
		boolean, isBoolean := difficulty.(bool)

		if !isBoolean || boolean {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: difficulty must be Simple, Intermediate, Advanced, or False", path)
		}

		selectable = false
	} else if difficultyName != "Simple" && difficultyName != "Intermediate" && difficultyName != "Advanced" {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: difficulty %q is invalid", path, difficultyName)
	}

	if selectable != (len(source.RecommendedJobs) > 0) {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: recommended_jobs must match difficulty selectability", path)
	}

	for _, job := range source.RecommendedJobs {
		if !strings.HasPrefix(job, "JOB_") {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: recommended_jobs has invalid %q", path, job)
		}
	}

	if source.Size == "" {
		source.Size = "medium"
	}

	if !allowedSizes[source.Size] {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: size %q is invalid", path, source.Size)
	}

	if source.UndeadType == "" {
		source.UndeadType = "US_ALIVE"
	}

	if !allowedUndead[source.UndeadType] {
		return content.SpeciesDef{}, 0, fmt.Errorf("%s: undead_type %q is invalid", path, source.UndeadType)
	}

	if source.LevelUpStats == nil {
		defaults := []string{"str", "int", "dex"}
		source.LevelUpStats = &defaults
	}

	for _, stat := range *source.LevelUpStats {
		if !allowedStats[stat] {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: levelup_stats has invalid %q", path, stat)
		}
	}

	aptitudes := make(map[string]content.SpeciesAptitude, len(ordinarySkills))

	for _, name := range ordinarySkills {
		aptitudes[skillID(name)] = content.SpeciesAptitude{Allowed: true}
	}

	var xp, hp, mp, mr int

	for name, node := range source.Aptitudes {
		switch name {
		case "xp", "hp", "mp_mod", "mr":
			min, max := -10, 10

			if name == "mp_mod" {
				min, max = -5, 20
			}

			if name == "mr" {
				min, max = 0, 20
			}

			value, err := yamlInt(path, name, node, min, max)

			if err != nil {
				return content.SpeciesDef{}, 0, err
			}

			switch name {
			case "xp":
				xp = value
			case "hp":
				hp = value
			case "mp_mod":
				mp = value
			case "mr":
				mr = value
			}
		default:
			id := skillID(name)

			if _, valid := aptitudes[id]; !valid {
				return content.SpeciesDef{}, 0, fmt.Errorf("%s: unknown aptitude %s", path, name)
			}

			var value any

			if err := node.Decode(&value); err != nil {
				return content.SpeciesDef{}, 0, fmt.Errorf("%s: %s: %w", path, name, err)
			}

			if boolean, isBoolean := value.(bool); isBoolean && !boolean {
				aptitudes[id] = content.SpeciesAptitude{Allowed: false}
				continue
			}

			n, ok := value.(int)

			if !ok || n < -10 || n > 10 {
				return content.SpeciesDef{}, 0, fmt.Errorf("%s: %s aptitude must be False or integer in -10..10", path, name)
			}

			aptitudes[id] = content.SpeciesAptitude{
				Allowed: true,
				Value:   n,
			}
		}
	}

	for _, required := range []string{
		"xp",
		"hp",
		"mp_mod",
		"mr",
	} {
		if _, present := source.Aptitudes[required]; !present {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: aptitudes.%s is required", path, required)
		}
	}

	flags := append([]string(nil), source.SpeciesFlags...)

	for _, flag := range flags {
		if !allowedFlags[flag] {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: invalid species_flags %s", path, flag)
		}
	}

	sort.Strings(flags)
	mutations := make([]content.SpeciesMutation, 0)

	for level, group := range source.Mutations {
		if level < 1 || level > 27 {
			return content.SpeciesDef{}, 0, fmt.Errorf("%s: mutations level %d out of range", path, level)
		}

		for id, amount := range group {
			if !strings.HasPrefix(id, "MUT_") || amount < -3 || amount > 3 {
				return content.SpeciesDef{}, 0, fmt.Errorf("%s: mutations.%s has invalid amount %d", path, id, amount)
			}

			mutations = append(mutations, content.SpeciesMutation{
				Level:  level,
				ID:     id,
				Amount: amount,
			})
		}
	}

	sort.Slice(mutations, func(i, j int) bool {
		if mutations[i].Level != mutations[j].Level {
			return mutations[i].Level < mutations[j].Level
		}

		return mutations[i].ID < mutations[j].ID
	})
	weapons := append([]string(nil), source.RecommendedWeapons...)

	if selectable {
		if len(weapons) == 0 {
			weapons = []string{
				"SK_LONG_BLADES",
				"SK_AXES",
				"SK_MACES_FLAILS",
				"SK_POLEARMS",
				"SK_STAVES",
				"SK_RANGED_WEAPONS",
			}
		}

		for _, weapon := range weapons {
			if !allowedWeapons[weapon] {
				return content.SpeciesDef{}, 0, fmt.Errorf("%s: invalid recommended_weapons %s", path, weapon)
			}
		}
	} else {
		weapons = nil
	}

	habitat := "HT_LAND"

	if source.CanSwim {
		habitat = "HT_WATER"
	}

	result := content.SpeciesDef{
		ID:                   source.Enum,
		MonsterID:            source.Monster,
		SourcePath:           path,
		Name:                 source.Name,
		ShortName:            source.ShortName,
		Adjective:            source.Adjective,
		Genus:                source.Genus,
		Selectable:           selectable,
		Difficulty:           difficultyName,
		DifficultyPriority:   source.DifficultyPriority,
		XP:                   xp,
		HP:                   hp,
		MPMod:                mp,
		MR:                   mr,
		Strength:             source.Strength,
		Intelligence:         source.Intelligence,
		Dexterity:            source.Dexterity,
		LevelUpStatFrequency: source.LevelUpFrequency,
		LevelUpStats:         append([]string(nil), (*source.LevelUpStats)...),
		Aptitudes:            aptitudes,
		Mutations:            mutations,
		FakeMutations:        append([]content.SpeciesFakeMutation(nil), source.FakeMutations...),
		Flags:                flags,
		Habitat:              habitat,
		Size:                 "SIZE_" + strings.ToUpper(source.Size),
		UndeadType:           source.UndeadType,
		RecommendedJobs:      append([]string(nil), source.RecommendedJobs...),
		RecommendedWeapons:   weapons,
		WalkingVerb:          source.WalkingVerb,
		AltarAction:          source.AltarAction,
	}

	return result, source.TagMajorVersion, nil
}
