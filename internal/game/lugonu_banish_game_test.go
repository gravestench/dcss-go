package game

import (
	"testing"

	"crawl/internal/modfs"
)

// Powered Lugonu banishment publishes an actual deep Abyss window and
// preserves the generated depth through the new Go save format.
func TestPoweredBanishmentEntersDeepAbyssAndRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/region-mod")

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

	if _, err := g.scripts.Policy("test.powered_banishment", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if position.LevelID != abyssStorageID || g.abyssState == nil ||
		g.abyssState.BranchDepth < 5 || g.abyssState.BranchDepth > 6 {
		t.Fatalf("powered banishment entered %+v, state %+v",
			position, g.abyssState)
	}

	loaded, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if loaded.abyssState == nil ||
		loaded.abyssState.BranchDepth != g.abyssState.BranchDepth {
		t.Fatal("powered Abyss entry depth changed across save and restore")
	}
}
