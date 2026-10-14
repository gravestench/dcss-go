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

type speciesAptitudes struct {
	skills map[string]content.SpeciesAptitude
	xp     int
	hp     int
	mp     int
	mr     int
}

func parseYAML(path string, data []byte) (content.SpeciesDef, int, error) {
	source, err := decodeSpeciesYAML(path, data)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	if err := validateSpeciesIdentity(path, &source); err != nil {
		return content.SpeciesDef{}, 0, err
	}

	selectable, difficultyName, err := parseSpeciesDifficulty(path, source)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	if err := applySpeciesDefaults(path, &source); err != nil {
		return content.SpeciesDef{}, 0, err
	}

	aptitudes, err := parseSpeciesAptitudes(path, source)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	flags, err := parseSpeciesFlags(path, source.SpeciesFlags)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	mutations, err := parseSpeciesMutations(path, source.Mutations)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	weapons, err := parseSpeciesWeapons(path, source.RecommendedWeapons, selectable)

	if err != nil {
		return content.SpeciesDef{}, 0, err
	}

	result := content.SpeciesDef{
		ID:         source.Enum,
		MonsterID:  source.Monster,
		SourcePath: path,

		Name:      source.Name,
		ShortName: source.ShortName,
		Adjective: source.Adjective,
		Genus:     source.Genus,

		Selectable:         selectable,
		Difficulty:         difficultyName,
		DifficultyPriority: source.DifficultyPriority,

		XP:    aptitudes.xp,
		HP:    aptitudes.hp,
		MPMod: aptitudes.mp,
		MR:    aptitudes.mr,

		Strength:             source.Strength,
		Intelligence:         source.Intelligence,
		Dexterity:            source.Dexterity,
		LevelUpStatFrequency: source.LevelUpFrequency,
		LevelUpStats:         append([]string(nil), (*source.LevelUpStats)...),

		Aptitudes:     aptitudes.skills,
		Mutations:     mutations,
		FakeMutations: append([]content.SpeciesFakeMutation(nil), source.FakeMutations...),
		Flags:         flags,

		Habitat:    speciesHabitat(source.CanSwim),
		Size:       "SIZE_" + strings.ToUpper(source.Size),
		UndeadType: source.UndeadType,

		RecommendedJobs:    append([]string(nil), source.RecommendedJobs...),
		RecommendedWeapons: weapons,

		WalkingVerb: source.WalkingVerb,
		AltarAction: source.AltarAction,
	}

	return result, source.TagMajorVersion, nil
}

func decodeSpeciesYAML(path string, data []byte) (sourceSpecies, error) {
	var tree yaml.Node

	if err := yaml.Unmarshal(data, &tree); err != nil {
		return sourceSpecies{}, fmt.Errorf("%s: %w", path, err)
	}

	if err := duplicateKeys(&tree, path); err != nil {
		return sourceSpecies{}, err
	}

	if err := validateSourceShape(path, &tree); err != nil {
		return sourceSpecies{}, err
	}

	decoder := yaml.NewDecoder(bytes.NewReader(data))
	decoder.KnownFields(true)
	var source sourceSpecies

	if err := decoder.Decode(&source); err != nil {
		return sourceSpecies{}, fmt.Errorf("%s: %w", path, err)
	}

	var trailing yaml.Node

	if err := decoder.Decode(&trailing); err != io.EOF {
		if err != nil {
			return sourceSpecies{}, fmt.Errorf("%s: trailing document: %w", path, err)
		}

		return sourceSpecies{}, fmt.Errorf("%s: multiple YAML documents are not supported", path)
	}

	return source, nil
}

func validateSpeciesIdentity(path string, source *sourceSpecies) error {
	if source.TagMajorVersion != 0 && source.TagMajorVersion != 34 {
		return fmt.Errorf("%s: TAG_MAJOR_VERSION %d is unsupported", path, source.TagMajorVersion)
	}

	if source.Name == "" ||
		source.Enum == "" || source.Monster == "" {
		return fmt.Errorf("%s: enum, monster, and name are required", path)
	}

	if source.ShortName == "" {
		if len(source.Name) < 2 {
			return fmt.Errorf("%s: name too short for short_name", path)
		}

		source.ShortName = source.Name[:2]
	}

	if source.Strength < 1 || source.Strength > 100 {
		return fmt.Errorf("%s: str out of range", path)
	}

	if source.Intelligence < 1 || source.Intelligence > 100 {
		return fmt.Errorf("%s: int out of range", path)
	}

	if source.Dexterity < 1 || source.Dexterity > 100 {
		return fmt.Errorf("%s: dex out of range", path)
	}

	if source.LevelUpFrequency < 0 || source.LevelUpFrequency > 28 {
		return fmt.Errorf("%s: levelup_stat_frequency out of range", path)
	}

	if source.DifficultyPriority < 0 || source.DifficultyPriority > 1000 {
		return fmt.Errorf("%s: difficulty_priority out of range", path)
	}

	return nil
}

func parseSpeciesDifficulty(path string, source sourceSpecies) (bool, string, error) {
	var difficulty any

	if err := source.Difficulty.Decode(&difficulty); err != nil {
		return false, "", fmt.Errorf("%s: difficulty: %w", path, err)
	}

	selectable := true
	difficultyName, ok := difficulty.(string)

	if !ok {
		boolean, isBoolean := difficulty.(bool)

		if !isBoolean || boolean {
			return false, "", fmt.Errorf(
				"%s: difficulty must be Simple, Intermediate, Advanced, or False",
				path,
			)
		}

		selectable = false
	} else if difficultyName != "Simple" &&
		difficultyName != "Intermediate" &&
		difficultyName != "Advanced" {
		return false, "", fmt.Errorf("%s: difficulty %q is invalid", path, difficultyName)
	}

	if selectable != (len(source.RecommendedJobs) > 0) {
		return false, "", fmt.Errorf("%s: recommended_jobs must match difficulty selectability", path)
	}

	for _, job := range source.RecommendedJobs {
		if !strings.HasPrefix(job, "JOB_") {
			return false, "", fmt.Errorf("%s: recommended_jobs has invalid %q", path, job)
		}
	}

	return selectable, difficultyName, nil
}

func applySpeciesDefaults(path string, source *sourceSpecies) error {
	if source.Size == "" {
		source.Size = "medium"
	}

	if !allowedSizes[source.Size] {
		return fmt.Errorf("%s: size %q is invalid", path, source.Size)
	}

	if source.UndeadType == "" {
		source.UndeadType = "US_ALIVE"
	}

	if !allowedUndead[source.UndeadType] {
		return fmt.Errorf("%s: undead_type %q is invalid", path, source.UndeadType)
	}

	if source.LevelUpStats == nil {
		defaults := []string{
			"str",
			"int",
			"dex",
		}

		source.LevelUpStats = &defaults
	}

	for _, stat := range *source.LevelUpStats {
		if !allowedStats[stat] {
			return fmt.Errorf("%s: levelup_stats has invalid %q", path, stat)
		}
	}

	return nil
}

func parseSpeciesAptitudes(path string, source sourceSpecies) (speciesAptitudes, error) {
	result := speciesAptitudes{
		skills: make(map[string]content.SpeciesAptitude, len(ordinarySkills)),
	}

	for _, name := range ordinarySkills {
		result.skills[skillID(name)] = content.SpeciesAptitude{Allowed: true}
	}

	for name, node := range source.Aptitudes {
		switch name {
		case "xp", "hp", "mp_mod", "mr":
			if err := parseSpeciesModifier(path, name, node, &result); err != nil {
				return speciesAptitudes{}, err
			}

		default:
			if err := parseSpeciesSkill(path, name, node, result.skills); err != nil {
				return speciesAptitudes{}, err
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
			return speciesAptitudes{}, fmt.Errorf("%s: aptitudes.%s is required", path, required)
		}
	}

	return result, nil
}

func parseSpeciesModifier(path, name string, node yaml.Node, result *speciesAptitudes) error {
	min, max := -10, 10

	if name == "mp_mod" {
		min, max = -5, 20
	}

	if name == "mr" {
		min, max = 0, 20
	}

	value, err := yamlInt(path, name, node, min, max)

	if err != nil {
		return err
	}

	switch name {
	case "xp":
		result.xp = value

	case "hp":
		result.hp = value

	case "mp_mod":
		result.mp = value

	case "mr":
		result.mr = value
	}

	return nil
}

func parseSpeciesSkill(
	path, name string,
	node yaml.Node,
	skills map[string]content.SpeciesAptitude,
) error {
	id := skillID(name)

	if _, valid := skills[id]; !valid {
		return fmt.Errorf("%s: unknown aptitude %s", path, name)
	}

	var value any

	if err := node.Decode(&value); err != nil {
		return fmt.Errorf("%s: %s: %w", path, name, err)
	}

	if boolean, isBoolean := value.(bool); isBoolean && !boolean {
		skills[id] = content.SpeciesAptitude{Allowed: false}

		return nil
	}

	n, ok := value.(int)

	if !ok ||
		n < -10 || n > 10 {
		return fmt.Errorf("%s: %s aptitude must be False or integer in -10..10", path, name)
	}

	skills[id] = content.SpeciesAptitude{
		Allowed: true,
		Value:   n,
	}

	return nil
}

func parseSpeciesFlags(path string, sourceFlags []string) ([]string, error) {
	flags := append([]string(nil), sourceFlags...)

	for _, flag := range flags {
		if !allowedFlags[flag] {
			return nil, fmt.Errorf("%s: invalid species_flags %s", path, flag)
		}
	}

	sort.Strings(flags)

	return flags, nil
}

func parseSpeciesMutations(
	path string,
	sourceMutations map[int]map[string]int,
) ([]content.SpeciesMutation, error) {
	mutations := make([]content.SpeciesMutation, 0)

	for level, group := range sourceMutations {
		if level < 1 || level > 27 {
			return nil, fmt.Errorf("%s: mutations level %d out of range", path, level)
		}

		for id, amount := range group {
			if !strings.HasPrefix(id, "MUT_") ||
				amount < -3 || amount > 3 {
				return nil, fmt.Errorf("%s: mutations.%s has invalid amount %d", path, id, amount)
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

	return mutations, nil
}

func parseSpeciesWeapons(path string, sourceWeapons []string, selectable bool) ([]string, error) {
	weapons := append([]string(nil), sourceWeapons...)

	if !selectable {
		return nil, nil
	}

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
			return nil, fmt.Errorf("%s: invalid recommended_weapons %s", path, weapon)
		}
	}

	return weapons, nil
}

func speciesHabitat(canSwim bool) string {
	if canSwim {
		return "HT_WATER"
	}

	return "HT_LAND"
}
