package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// Both Xom travel outcomes use the live Abyss region and saved origin.
// Pseudo banishment returns immediately; real banishment survives a save.
func TestXomBanishmentTravelAndRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/xom-actions")

	if err != nil {
		t.Fatal(err)
	}

	for _, scenario := range []struct {
		name           string
		policy         string
		wantLevelID    int
		wantBanishment bool
	}{
		{
			name:           "real",
			policy:         "test.xom_banishment",
			wantLevelID:    abyssStorageID,
			wantBanishment: true,
		},

		{
			name:           "pseudo",
			policy:         "test.xom_pseudo_banishment",
			wantLevelID:    1,
			wantBanishment: false,
		},
	} {
		t.Run(scenario.name, func(t *testing.T) {
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

			if _, err := g.scripts.Policy(scenario.policy, nil); err != nil {
				t.Fatal(err)
			}

			if err := g.scripts.ApplyPending(); err != nil {
				t.Fatal(err)
			}

			position, found := g.stores.Positions.Get(g.player)

			if !found || position.LevelID != scenario.wantLevelID {
				t.Fatalf("Xom travel position = %+v, found %v", position, found)
			}

			if g.scripts.Components()["world.banishment"].Has(g.player) !=
				scenario.wantBanishment {
				t.Fatal("Xom travel has wrong saved return-site state")
			}

			// The test invokes a Lua policy directly. An ordinary player action
			// refreshes sight before saving, and restore does the same.
			if err := g.refreshVisibility(); err != nil {
				t.Fatal(err)
			}

			snapshot := g.Snapshot()
			restored, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

			if err != nil {
				t.Fatal(err)
			}

			defer restored.Close()

			if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
				t.Fatal("Xom travel snapshot changed across restore")
			}
		})
	}
}
