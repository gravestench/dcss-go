package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

func TestMutationScreenShowsMundanePlayerWithoutSpendingTime(t *testing.T) {
	m := playingModel(t)
	before := m.game.View().CurrentAut

	m.handleKey("A")

	if m.screen != ScreenMutations {
		t.Fatal("A did not open the mutation screen")
	}

	page := plainApp(m)

	if !strings.Contains(page, "Innate Abilities, Weirdness & Mutations") ||
		!strings.Contains(page, "You are rather mundane.") {
		t.Fatalf("mutation screen lost source text:\n%s", page)
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != before {
		t.Fatal("opening or closing mutations changed the game turn")
	}
}

func TestMutationScreenShowsInnateSourceDescription(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_MINOTAUR",
		"JOB_FIGHTER",
		"WPN_WAR_AXE",
		"Minotaur",
	)

	if err != nil {
		t.Fatal(err)
	}

	m.game = g
	m.screen = ScreenPlay
	m.handleKey("A")

	page := plainApp(m)

	if !strings.Contains(page, "You have a pair of horns on your head.") {
		t.Fatalf("innate horns did not use the live Lua mutation definition:\n%s", page)
	}

	m.handleKey("a")

	if !strings.Contains(plainApp(m), "You have horns on your head") {
		t.Fatal("mutation examine did not show the source long description")
	}

	m.handleKey("esc")

	if !strings.Contains(plainApp(m), "You have a pair of horns on your head.") {
		t.Fatal("mutation examine did not return to the list")
	}

	before := m.game.View().CurrentAut
	m.handleKey("pgdown")

	if m.mutationPage != 0 || m.game.View().CurrentAut != before {
		t.Fatal("paging past the only mutation page changed state or time")
	}
}

func TestMutationExamineReturnsToItsListPage(t *testing.T) {
	m := playingModel(t)

	m.mutationPage = 2
	m.mutationPages = 3
	m.mutationOptions = map[string]string{
		"a": "MUT_HORNS",
	}

	m.applyMutationDecision("mutation_detail", map[string]any{
		"id": "MUT_HORNS",
	})

	if m.mutationSelected != "MUT_HORNS" || m.mutationPage != 0 {
		t.Fatal("mutation examination did not start on its first page")
	}

	m.applyMutationDecision("mutation_close_detail", map[string]any{})

	if m.mutationSelected != "" || m.mutationPage != 2 {
		t.Fatal("mutation examination lost the prior list page")
	}
}

func TestMutationScreenShowsSourceSpeciesTraits(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_FORMICID",
		"JOB_FIGHTER",
		"WPN_WAR_AXE",
		"Formicid",
	)

	if err != nil {
		t.Fatal(err)
	}

	m.game = g
	m.screen = ScreenPlay
	m.handleKey("A")

	page := plainApp(m)

	if !strings.Contains(page, "You cannot be hasted, slowed") ||
		!strings.Contains(page, "You can dig through walls") {
		t.Fatalf("species traits missing from mutation screen:\n%s", page)
	}
}
