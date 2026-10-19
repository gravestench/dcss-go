package game

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
)

func TestGameUsesEffectiveLuaCharacterDefinitions(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/character-override")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	attributes, found := g.stores.Attributes.Get(g.player)

	if !found || attributes.Strength != 17 {
		t.Fatalf("Lua species override did not change starting strength: %+v", attributes)
	}
}

func TestJobGearOverrideChangesStartingInventory(t *testing.T) {
	rules, err := modfs.Load("testdata/job-gear-override")

	if err != nil {
		t.Fatal(err)
	}

	game, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer game.Close()

	curingFound := false

	for _, item := range game.View().Inventory {
		if item.KindID == "POT_MIGHT" {
			t.Fatal("the bundled Fighter grant survived a job-file override")
		}

		if item.KindID == "POT_CURING" {
			curingFound = true
		}
	}

	if !curingFound {
		t.Fatal("the overlaid Fighter grant was not given")
	}
}

func TestInvalidJobGearReportsDefinitionOrigin(t *testing.T) {
	rules, err := modfs.Load("testdata/job-gear-invalid")

	if err != nil {
		t.Fatal(err)
	}

	game, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if game != nil {
		game.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "content/jobs/job_fighter.lua") ||
		!strings.Contains(err.Error(), "impossible charges") {
		t.Fatalf("invalid job grant error = %v", err)
	}
}

func TestGameRespectsLuaCharacterChoicePolicy(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/ban-all")

	if err != nil {
		t.Fatal(err)
	}

	_, err = newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err == nil {
		t.Fatal("Lua policy did not block banned start")
	}
}

func TestLuaPolicyCanEnableModdedCharacterCombination(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/allow-all")

	if err != nil {
		t.Fatal(err)
	}

	g, err := NewDungeonGameWithRules(
		1,
		"SP_FELID",
		"JOB_GLADIATOR",
		"WPN_UNARMED",
		"Tester",
		rules,
	)

	if err != nil {
		t.Fatalf("Lua choice override could not start its character: %v", err)
	}

	defer g.Close()

	if g.View().SpeciesID != "SP_FELID" ||
		g.View().CharacterName != "Felid Gladiator" {
		t.Fatal("modded character combination changed after start")
	}
}
