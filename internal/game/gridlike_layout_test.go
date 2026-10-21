package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
	"crawl/internal/vault"
)

// A DES overlay changes only eligibility so the production Gridlike hook,
// keyed plant record, ECS population, and Go save path run together.
func TestGridlikePlantFillMaterializesAndRestores(t *testing.T) {
	rules, err := modfs.Load("testdata/gridlike-layout")

	if err != nil {
		t.Fatal(err)
	}

	for seed := uint64(1); seed <= 64; seed++ {
		g, gameErr := NewDungeonGameWithRules(
			seed,
			"SP_HUMAN",
			"JOB_FIGHTER",
			"WPN_RAPIER",
			"Tester",
			rules,
		)

		if gameErr != nil {
			t.Fatal(gameErr)
		}

		// The fixture only tests generation. Raise travel health before the
		// stair action, then restore the legal character value for saving.
		health, _ := g.stores.Health.Get(g.player)
		originalMax := health.Max
		health.Max = 10000
		health.Current = health.Max
		descendGeneratedTo(t, g, 2)

		level := g.levels[2]
		plantRecord := false

		for _, record := range level.VaultRecords() {
			if record.Kind == vault.KindMonster &&
				record.Identity == "plant" &&
				record.SourceID == "layout_gridlike" {
				plantRecord = true
				break
			}
		}

		if !plantRecord {
			_ = g.Close()
			continue
		}

		plantEntity := false

		for _, entity := range g.stores.Actors.Entities() {
			actor, exists := g.stores.Actors.Get(entity)

			if exists && actor.KindID == "MONS_PLANT" &&
				g.scripts.Components()["vault.origin"].Has(entity) {
				plantEntity = true
				break
			}
		}

		if !plantEntity {
			t.Fatal("Gridlike plant record did not spawn an ECS plant")
		}

		health.Max = originalMax
		health.Current = originalMax

		snapshot := g.Snapshot()
		restored, restoreErr := RestoreWithRules(snapshot,
			rules, RestorePolicy{})

		if restoreErr != nil {
			t.Fatal(restoreErr)
		}

		defer restored.Close()
		defer g.Close()

		if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
			t.Fatal("Gridlike plant fill changed across save and restore")
		}

		return
	}

	t.Fatal("no Gridlike plant fill appeared in 64 fixed seeds")
}
