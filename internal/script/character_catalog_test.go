package script

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/modfs"
	"github.com/gravestench/akara"
)

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

	if len(runtime.SpeciesDefinitions()) != 43 ||
		len(runtime.JobDefinitions()) != 31 {
		t.Fatalf(
			"incomplete Lua character catalog: %d species, %d jobs",
			len(runtime.SpeciesDefinitions()),
			len(runtime.JobDefinitions()),
		)
	}

	for _, definition := range runtime.SpeciesDefinitions() {
		pinned, err := base.Species(definition.ID)

		if err != nil {
			t.Fatal(err)
		}

		if !reflect.DeepEqual(definition, pinned) {
			t.Fatalf("Lua species %s differs from pinned import", definition.ID)
		}
	}

	for _, definition := range runtime.JobDefinitions() {
		pinned, err := base.Job(definition.ID)

		if err != nil {
			t.Fatal(err)
		}

		if !reflect.DeepEqual(definition, pinned) {
			t.Fatalf("Lua job %s differs from pinned import", definition.ID)
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
	base, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

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

	catalog, choices, err := ProjectCharacterCatalog(base, override)

	if err != nil {
		t.Fatal(err)
	}

	human, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

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
	base, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("testdata/ban-all")

	if err != nil {
		t.Fatal(err)
	}

	_, choices, err := ProjectCharacterCatalog(base, rules)

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
	base, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("testdata/add-species")

	if err != nil {
		t.Fatal(err)
	}

	catalog, _, err := ProjectCharacterCatalog(base, rules)

	if err != nil {
		t.Fatal(err)
	}

	added, err := catalog.Species("SP_MOON_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if added.Name != "Moon Human" || !added.Selectable {
		t.Fatalf("added Lua species changed unexpectedly: %+v", added)
	}

	presentation := catalog.Presentation()
	lastGroup := presentation.SpeciesGroups[len(presentation.SpeciesGroups)-1]

	if len(lastGroup.IDs) != 1 || lastGroup.IDs[0] != added.ID {
		t.Fatalf("added selectable species is absent from menu: %+v", lastGroup)
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
	base, err := content.LoadDefault()

	if err != nil {
		t.Fatal(err)
	}

	rules, err := modfs.Load("testdata/disable-human")

	if err != nil {
		t.Fatal(err)
	}

	catalog, choices, err := ProjectCharacterCatalog(base, rules)

	if err != nil {
		t.Fatal(err)
	}

	human, err := catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if human.Selectable {
		t.Fatal("Lua selectability override was ignored")
	}

	for _, group := range catalog.Presentation().SpeciesGroups {
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
		!strings.Contains(err.Error(), "missing required field") {
		t.Fatalf("incomplete definition lacks context: %v", err)
	}
}
