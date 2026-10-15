package game

import (
	"testing"

	"dcrawl-go/internal/modfs"
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

func TestLuaPolicyCannotEnableUnimplementedStart(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/allow-all")

	if err != nil {
		t.Fatal(err)
	}

	_, err = NewDungeonGameWithRules(
		1,
		"SP_HUMAN",
		"JOB_BERSERKER",
		"",
		"Tester",
		rules,
	)

	if err == nil {
		t.Fatal("Lua policy enabled an unimplemented start")
	}
}
