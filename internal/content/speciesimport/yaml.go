package speciesimport

import (
	"fmt"
	"strings"

	"dcrawl-go/internal/content"
	"gopkg.in/yaml.v3"
)

type sourceSpecies struct {
	TagMajorVersion int    `yaml:"TAG_MAJOR_VERSION"`
	Enum            string `yaml:"enum"`
	Monster         string `yaml:"monster"`

	Name      string `yaml:"name"`
	ShortName string `yaml:"short_name"`
	Adjective string `yaml:"adjective"`
	Genus     string `yaml:"genus"`

	Difficulty         yaml.Node            `yaml:"difficulty"`
	DifficultyPriority int                  `yaml:"difficulty_priority"`
	Aptitudes          map[string]yaml.Node `yaml:"aptitudes"`

	SpeciesFlags []string `yaml:"species_flags"`
	CanSwim      bool     `yaml:"can_swim"`
	UndeadType   string   `yaml:"undead_type"`
	Size         string   `yaml:"size"`

	Strength         int       `yaml:"str"`
	Intelligence     int       `yaml:"int"`
	Dexterity        int       `yaml:"dex"`
	LevelUpFrequency int       `yaml:"levelup_stat_frequency"`
	LevelUpStats     *[]string `yaml:"levelup_stats"`

	Mutations     map[int]map[string]int        `yaml:"mutations"`
	FakeMutations []content.SpeciesFakeMutation `yaml:"fake_mutations"`

	RecommendedJobs    []string `yaml:"recommended_jobs"`
	RecommendedWeapons []string `yaml:"recommended_weapons"`

	WalkingVerb string `yaml:"walking_verb"`
	AltarAction string `yaml:"altar_action"`
	CreateEnum  bool   `yaml:"create_enum"`
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
	if root.Kind != yaml.DocumentNode ||
		len(root.Content) != 1 ||
		root.Content[0].Kind != yaml.MappingNode {
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
			if value.Kind != yaml.ScalarNode ||
				(value.Tag != "!!str" &&
					value.Tag != "!!bool") {
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

				if aptValue.Kind != yaml.ScalarNode ||
					(aptValue.Tag != "!!int" &&
						aptValue.Tag != "!!bool") {
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
