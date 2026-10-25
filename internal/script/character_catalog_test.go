package script

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"crawl/internal/modfs"
	"github.com/gravestench/akara"
)

type speciesView struct {
	ID         string
	Name       string
	Selectable bool
}

func registeredSpecies(t *testing.T, runtime *Runtime, id string) speciesView {
	t.Helper()

	definition, err := runtime.Definition("species", id)

	if err != nil {
		t.Fatal(err)
	}

	name, _ := definition["name"].(string)
	selectable, _ := definition["selectable"].(bool)

	return speciesView{
		ID:         id,
		Name:       name,
		Selectable: selectable,
	}
}

func TestBundledLuaCharacterCatalogAndChoices(t *testing.T) {
	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	speciesIDs := runtime.DefinitionIDs("species")
	jobIDs := runtime.DefinitionIDs("jobs")

	if len(speciesIDs) != 43 || len(jobIDs) != 31 {
		t.Fatalf("incomplete Lua character catalog: %d species, %d jobs",
			len(speciesIDs), len(jobIDs))
	}

	for _, speciesID := range speciesIDs {
		for _, jobID := range jobIDs {
			for _, speciesFirst := range []bool{false, true} {
				choice, err := runtime.CharacterChoice(
					speciesID, jobID, speciesFirst,
				)

				if err != nil {
					t.Fatal(err)
				}

				switch choice.Restriction {
				case "banned", "restricted", "recommended":

				default:
					t.Fatalf("invalid Lua restriction %q", choice.Restriction)
				}

				if choice.Playable && choice.Restriction == "banned" {
					t.Fatalf("banned Lua choice %s/%s is playable",
						speciesID, jobID)
				}
			}
		}
	}
}

func TestBundledCharacterMenuUsesEffectiveDefinitions(t *testing.T) {
	rules, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	menu, _, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := NewCatalog(world, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	for _, entry := range []struct {
		category     string
		ids          []string
		descriptions map[string]string
	}{
		{
			category:     "species",
			ids:          menu.SpeciesIDs(),
			descriptions: menu.SpeciesDescriptions,
		},

		{
			category:     "jobs",
			ids:          menu.JobIDs(),
			descriptions: menu.JobDescriptions,
		},
	} {
		seen := make(map[string]bool)

		for _, id := range entry.ids {
			if seen[id] {
				t.Fatalf("duplicate %s menu ID %s", entry.category, id)
			}

			seen[id] = true

			definition, err := runtime.Definition(entry.category, id)

			if err != nil {
				t.Fatal(err)
			}

			if definition["selectable"] != true || entry.descriptions[id] == "" {
				t.Fatalf("%s %s lacks selectable definition or description",
					entry.category, id)
			}
		}

		for _, id := range runtime.DefinitionIDs(entry.category) {
			definition, err := runtime.Definition(entry.category, id)

			if err != nil {
				t.Fatal(err)
			}

			if definition["selectable"] == true && !seen[id] {
				t.Fatalf("selectable %s %s is absent from menu",
					entry.category, id)
			}
		}
	}
}

func TestCharacterOverrideChangesEffectiveCatalog(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	override, err := modfs.Load("testdata/character-override")

	if err != nil {
		t.Fatal(err)
	}

	if override.Hash() == bundled.Hash() || override.Vanilla() {
		t.Fatal("character override did not change ruleset identity")
	}

	menu, choices, err := ProjectCharacterMenu(override)

	if err != nil {
		t.Fatal(err)
	}

	if len(menu.SpeciesIDs()) == 0 {
		t.Fatal("Lua menu has no species")
	}

	if menu.SpeciesDescriptions["SP_HUMAN"] !=
		"Moon Humans are at home under moonlight." {
		t.Fatalf("Lua species description override was ignored: %q",
			menu.SpeciesDescriptions["SP_HUMAN"])
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, override, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	human := registeredSpecies(t, runtime, "SP_HUMAN")

	if human.Name != "Moon Human" {
		t.Fatalf("Lua species override was ignored: %q", human.Name)
	}

	choice := choices[ChoiceKey{
		SpeciesID:    "SP_HUMAN",
		JobID:        "JOB_FIGHTER",
		SpeciesFirst: true,
	}]

	if !choice.Playable {
		t.Fatal("unchanged Fighter start became unavailable")
	}
}

func TestChoicePolicyOverrideControlsMenu(t *testing.T) {
	rules, err := modfs.Load("testdata/ban-all")

	if err != nil {
		t.Fatal(err)
	}

	_, choices, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	choice := choices[ChoiceKey{
		SpeciesID:    "SP_HUMAN",
		JobID:        "JOB_FIGHTER",
		SpeciesFirst: true,
	}]

	if choice.Restriction != "banned" || choice.Playable {
		t.Fatalf("mod policy was ignored: %+v", choice)
	}
}

func TestAddedLuaSpeciesIsRegistered(t *testing.T) {
	rules, err := modfs.Load("testdata/add-species")

	if err != nil {
		t.Fatal(err)
	}

	menu, _, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	added := registeredSpecies(t, runtime, "SP_MOON_HUMAN")

	if added.Name != "Moon Human" || !added.Selectable {
		t.Fatalf("added Lua species changed unexpectedly: %+v", added)
	}

	lastGroup := menu.SpeciesGroups[len(menu.SpeciesGroups)-1]

	if len(lastGroup.IDs) != 1 || lastGroup.IDs[0] != added.ID {
		t.Fatalf("added selectable species is absent from menu: %+v", lastGroup)
	}
}

func TestAddedLuaSpeciesKeepsModFields(t *testing.T) {
	rules, err := modfs.Load("testdata/add-species")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	result, err := runtime.Policy("test.lunar_affinity", nil)

	if err != nil {
		t.Fatal(err)
	}

	if result["value"] != int64(7) {
		t.Fatalf("Lua extension field was lost: %+v", result)
	}
}

func TestDuplicateLuaSpeciesFailsStartup(t *testing.T) {
	rules, err := modfs.Load("testdata/duplicate-species")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		runtime.Close()
	}

	if err == nil {
		t.Fatal("duplicate Lua species was accepted")
	}
}

func TestLuaSelectabilityOverrideRemovesMenuEntry(t *testing.T) {
	rules, err := modfs.Load("testdata/disable-human")

	if err != nil {
		t.Fatal(err)
	}

	menu, choices, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if err != nil {
		t.Fatal(err)
	}

	defer runtime.Close()

	human := registeredSpecies(t, runtime, "SP_HUMAN")

	if human.Selectable {
		t.Fatal("Lua selectability override was ignored")
	}

	for _, group := range menu.SpeciesGroups {
		for _, id := range group.IDs {
			if id == "SP_HUMAN" {
				t.Fatal("nonselectable Human remains in the menu")
			}
		}
	}

	choice := choices[ChoiceKey{
		SpeciesID:    "SP_HUMAN",
		JobID:        "JOB_FIGHTER",
		SpeciesFirst: true,
	}]

	if choice.Restriction != "banned" || choice.Playable {
		t.Fatalf("nonselectable Human became playable: %+v", choice)
	}
}

func replaceBundledCharacterText(
	t *testing.T,
	path string,
	original string,
	replacement string,
) (modfs.Ruleset, modfs.Ruleset) {
	t.Helper()
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	source, err := bundled.ReadFile(path)

	if err != nil {
		t.Fatal(err)
	}

	if strings.Count(string(source), original) != 1 {
		t.Fatalf("character source field %q changed", original)
	}

	root := t.TempDir()
	file := filepath.Join(root, filepath.FromSlash(path))

	if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
		t.Fatal(err)
	}

	changed := strings.Replace(string(source), original, replacement, 1)

	if err := os.WriteFile(file, []byte(changed), 0o644); err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load(root)

	if err != nil {
		t.Fatal(err)
	}

	return bundled, rules
}

func TestSamePathSpeciesDescriptionOverrideChangesMenu(t *testing.T) {
	const path = "content/species/sp_human.lua"
	const original = "Humans advance quickly"
	const replacement = "Moon humans advance quickly"

	bundled, rules := replaceBundledCharacterText(
		t, path, original, replacement)

	menu, _, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(menu.SpeciesDescriptions["SP_HUMAN"], replacement) {
		t.Fatalf("Human menu description = %q",
			menu.SpeciesDescriptions["SP_HUMAN"])
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("description override did not change ruleset identity")
	}
}

func TestSamePathSpeciesGroupRemovalMovesChoiceToModdedPage(t *testing.T) {
	_, rules := replaceBundledCharacterText(
		t,
		"content/species/sp_human.lua",
		"    difficulty = groups.SPECIES_INTERMEDIATE,\n"+
			"    difficulty_priority = 100,\n",
		"",
	)

	menu, _, err := ProjectCharacterMenu(rules)

	if err != nil {
		t.Fatal(err)
	}

	groups := menu.SpeciesGroups

	if len(groups) != 4 || groups[3].Label != "Modded species" {
		t.Fatalf("missing Modded species group: %+v", groups)
	}

	if len(groups[3].IDs) != 1 || groups[3].IDs[0] != "SP_HUMAN" {
		t.Fatalf("Human was not moved to Modded species: %+v", groups[3])
	}
}

func TestIncompleteLuaDefinitionNamesPathAndField(t *testing.T) {
	rules, err := modfs.Load("testdata/incomplete-species")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		runtime.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/species/sp_incomplete.lua") ||
		!strings.Contains(err.Error(), "SP_INCOMPLETE") ||
		!strings.Contains(err.Error(), "requires") {
		t.Fatalf("incomplete definition lacks context: %v", err)
	}
}

func TestMissingAptitudeFailsDuringLuaBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/missing-aptitude")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		runtime.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/species/sp_human.lua") ||
		!strings.Contains(err.Error(), "missing aptitude SK_FIGHTING") {
		t.Fatalf("missing aptitude did not fail at boot with context: %v", err)
	}
}

func TestMissingRecommendationNamesOwningDefinition(t *testing.T) {
	rules, err := modfs.Load("testdata/missing-recommendation")

	if err != nil {
		t.Fatal(err)
	}

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		runtime.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/species/sp_human.lua") ||
		!strings.Contains(err.Error(), "SP_HUMAN recommends missing job JOB_NOT_THERE") {
		t.Fatalf("missing recommendation lacks definition context: %v", err)
	}
}

func TestDuplicateMenuOrderFailsDuringLuaBoot(t *testing.T) {
	_, rules := replaceBundledCharacterText(
		t,
		"content/species/sp_human.lua",
		"difficulty_priority = 100,",
		"difficulty_priority = 90,",
	)

	world := akara.NewWorld()
	defer world.Close()

	runtime, err := newRuntimeWithHostComponents(t, world, rules, Services{})

	if runtime != nil {
		runtime.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/species/sp_human.lua") ||
		!strings.Contains(err.Error(), "duplicates menu order") {
		t.Fatalf("duplicate menu order did not fail at boot: %v", err)
	}
}
