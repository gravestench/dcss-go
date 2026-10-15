package terminal

import (
	"testing"

	"dcrawl-go/internal/game"
	"dcrawl-go/internal/modfs"
)

func TestAddedLuaSpeciesAppearsOnModdedMenuPage(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/add-species")

	if err != nil {
		t.Fatal(err)
	}

	model, err := NewAppModelWithRules(
		1,
		"",
		rules,
		game.RestorePolicy{},
	)

	if err != nil {
		t.Fatal(err)
	}

	defer model.Close()

	model.screen = ScreenSpecies
	model.focus = 27

	start, end, groups := characterChoicePage(
		model.presentation.SpeciesGroups,
		model.focus,
		model.screen,
	)

	if start != 27 ||
		end != 28 ||
		len(groups) != 1 ||
		groups[0].IDs[0] != "SP_MOON_HUMAN" {
		t.Fatalf("added species is not on a usable page: %d %d %+v", start, end, groups)
	}

	color, background := model.characterChoiceColors("SP_MOON_HUMAN", 27)

	if color != White || background == DarkGrey {
		t.Fatalf(
			"modded choice is not visibly available: %v/%v",
			color, background,
		)
	}

	model.selectSpecies("SP_MOON_HUMAN")

	if model.screen != ScreenBackground || model.speciesID != "SP_MOON_HUMAN" {
		t.Fatal("modded species did not enter character creation")
	}
}
