package game

import (
	"reflect"
	"testing"

	"crawl/internal/modfs"
)

// A named unique generated onto an actual monster retains its carrier,
// equipment slot, artefact identity, and run history through Go restore.
func TestSignatureMonsterGearSurvivesRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/signature-gear-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, rules)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if _, err := g.scripts.Policy("test.signature_gear", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	before := g.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before.Entities, loaded.Snapshot().Entities) ||
		!reflect.DeepEqual(before.RNG, loaded.Snapshot().RNG) {
		t.Fatal("restored monster signature item or RNG changed")
	}

	found := false

	for _, entity := range loaded.stores.CarriedBy.Entities() {
		if !loaded.stores.Equipped.Has(entity) {
			continue
		}

		state, present := loaded.scripts.Components()["item.artefact"].Get(entity)

		if !present {
			continue
		}

		uniqueID, err := state.Get("unique_id")

		if err == nil && uniqueID == "UNRAND_DISPATER" {
			found = true
			break
		}
	}

	if !found {
		t.Fatal("restored monster lost the staff of Dispater")
	}
}
