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

	base := testCatalog(t)
	g, err := newScenarioWithRules(
		1,
		base,
		base.Player(),
		"WPN_RAPIER",
		"Tester",
		ordinaryMonsterScenarioID,
		rules,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	human, err := g.catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	if human.Name != "Moon Human" {
		t.Fatalf("game ignored effective Lua species: %q", human.Name)
	}
}

func TestGameRespectsLuaCharacterChoicePolicy(t *testing.T) {
	rules, err := modfs.Load("../script/testdata/ban-all")

	if err != nil {
		t.Fatal(err)
	}

	base := testCatalog(t)
	_, err = newScenarioWithRules(
		1,
		base,
		base.Player(),
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
		testCatalog(t),
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
