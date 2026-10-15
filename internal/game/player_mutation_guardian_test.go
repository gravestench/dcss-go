package game

import (
	"testing"

	"dcrawl-go/internal/modfs"
)

func TestDemonicGuardianAppearsAfterSevereDamageAndRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/guardian")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		29,
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
	addPlayerMutation(t, g, "MUT_DEMONIC_GUARDIAN")

	_, err = g.scripts.Policy("test.guardian_damage", nil)

	if err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	guardianStore := g.scripts.Components()["character.demonic_guardian"]
	state, found := guardianStore.Get(g.player)

	if !found {
		t.Fatal("severe damage did not start guardian cooldown")
	}

	remaining, err := state.Get("cooldown_aut")

	if err != nil ||
		remaining.(int64) <= 0 {
		t.Fatalf("guardian cooldown = %v, %v", remaining, err)
	}

	summonStore := g.scripts.Components()["magic.summon"]
	guardians := summonStore.Entities()

	if len(guardians) != 1 {
		t.Fatalf("severe damage produced %d guardians, want one", len(guardians))
	}

	summoned, _ := summonStore.Get(guardians[0])
	owner, err := summoned.Get("owner")

	if err != nil ||
		owner != g.player {
		t.Fatalf("guardian owner = %v, %v", owner, err)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !restored.scripts.Components()["magic.summon"].Has(guardians[0]) ||
		!restored.scripts.Components()["character.demonic_guardian"].Has(restored.player) {
		t.Fatal("restore lost the guardian or its cooldown")
	}
}
