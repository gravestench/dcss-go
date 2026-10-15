package script

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
	lua "github.com/yuin/gopher-lua"
)

func registeredSpecies(t *testing.T, runtime *Runtime, id string) content.SpeciesDef {
	t.Helper()

	raw, err := luaDefinitionValue(
		runtime.definitions["species"][id], make(map[*lua.LTable]bool))

	if err != nil {
		t.Fatal(err)
	}

	data, err := json.Marshal(raw)

	if err != nil {
		t.Fatal(err)
	}

	var definition content.SpeciesDef

	if err := json.Unmarshal(data, &definition); err != nil {
		t.Fatal(err)
	}

	return definition
}

func registeredJob(t *testing.T, runtime *Runtime, id string) content.JobDef {
	t.Helper()

	raw, err := luaDefinitionValue(
		runtime.definitions["jobs"][id], make(map[*lua.LTable]bool))

	if err != nil {
		t.Fatal(err)
	}

	data, err := json.Marshal(raw)

	if err != nil {
		t.Fatal(err)
	}

	var definition content.JobDef

	if err := json.Unmarshal(data, &definition); err != nil {
		t.Fatal(err)
	}

	return definition
}

func TestBundledLuaCharacterCatalogMatchesPinnedImport(t *testing.T) {
	base, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("")

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

	if len(runtime.DefinitionIDs("species")) != 43 ||
		len(runtime.DefinitionIDs("jobs")) != 31 {
		t.Fatalf(
			"incomplete Lua character catalog: %d species, %d jobs",
			len(runtime.DefinitionIDs("species")),
			len(runtime.DefinitionIDs("jobs")),
		)
	}

	for _, id := range runtime.DefinitionIDs("species") {
		definition := registeredSpecies(t, runtime, id)
		pinned, err := base.Species(id)

		if err != nil {
			t.Fatal(err)
		}

		if !reflect.DeepEqual(definition, pinned) {
			t.Fatalf("Lua species %s differs from pinned import", id)
		}
	}

	for _, id := range runtime.DefinitionIDs("jobs") {
		definition := registeredJob(t, runtime, id)
		pinned, err := base.Job(id)

		if err != nil {
			t.Fatal(err)
		}

		if !reflect.DeepEqual(definition, pinned) {
			t.Fatalf("Lua job %s differs from pinned import", id)
		}
	}

	for _, speciesID := range base.SpeciesIDs() {
		for _, jobID := range base.JobIDs() {
			for _, speciesFirst := range []bool{false, true} {
				choice, err := runtime.CharacterChoice(
					speciesID, jobID, speciesFirst,
				)

				if err != nil {
					t.Fatal(err)
				}

				if choice.Restriction == "" {
					t.Fatalf("missing Lua choice for %s/%s", speciesID, jobID)
				}

				if choice.Restriction != "banned" &&
					choice.Restriction != "restricted" &&
					choice.Restriction != "recommended" {
					t.Fatalf("invalid Lua restriction %q", choice.Restriction)
				}

				if choice.Playable && choice.Restriction == "banned" {
					t.Fatalf("banned Lua choice %s/%s is playable", speciesID, jobID)
				}
			}
		}
	}
}

func TestCharacterOverrideChangesEffectiveCatalog(t *testing.T) {
	bundled, err := modfs.Load("")

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

func TestDuplicateMenuIDFailsDuringLuaBoot(t *testing.T) {
	rules, err := modfs.Load("testdata/duplicate-menu")

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
		!strings.Contains(err.Error(), "data/presentation.lua") ||
		!strings.Contains(err.Error(), "duplicate") {
		t.Fatalf("duplicate menu ID did not fail at boot: %v", err)
	}
}
