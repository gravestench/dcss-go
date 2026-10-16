package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestSparseScrollModRequiresEffectAndCanRead(t *testing.T) {
	content := "testdata/scroll-mod-content"
	effect := "testdata/scroll-mod-effect"
	missing, err := modfs.Load(content)

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
		missing,
	)

	if err == nil {
		t.Fatal("scroll without effect booted")
	}

	if !strings.Contains(err.Error(), "has no effect") {
		t.Fatalf("scroll without effect booted: %v", err)
	}

	rules, err := modfs.Load(content, effect)

	if err != nil {
		t.Fatal(err)
	}

	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	if rules.Hash() == bundled.Hash() {
		t.Fatal("new scroll left the ruleset hash unchanged")
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

	scroll := addIdentificationTestItem(t, g, "SCR_MOD_TEST", true)
	health, _ := g.stores.Health.Get(g.player)

	health.Current = health.Max - 1
	g.stores.Health.Set(g.player, *health)

	result, err := g.Step(Command{
		Kind:   CommandRead,
		ItemID: uint64(scroll),
	})

	if err != nil {
		t.Fatal(err)
	}

	healed, _ := g.stores.Health.Get(g.player)

	if result.Spent != 10 || healed.Current != healed.Max {
		t.Fatalf("scroll spent %d aut, HP %d/%d",
			result.Spent, healed.Current, healed.Max)
	}
}
