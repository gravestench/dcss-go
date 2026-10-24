package game

import (
	"testing"

	"crawl/internal/modfs"
)

// Yredelemnul's wrath zombie has a separate source god and base kind.
// Both must remain attached to the same living undead after restore.
func TestYredelemnulDerivedUndeadSurvivesRestore(t *testing.T) {
	rules, err := modfs.Load("testdata/avatar-wrath-mod")

	if err != nil {
		t.Fatal(err)
	}

	g, err := newScenarioWithRules(
		41,
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

	if _, err := g.scripts.Policy("test.yred_derived_undead", nil); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Policy("test.yred_permanent_gift", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	undead := g.scripts.Components()["magic.summon_undead"].Entities()

	if len(undead) != 1 {
		t.Fatalf("Yredelemnul derived undead = %d, want 1", len(undead))
	}

	base, found := g.scripts.Components()["magic.summon_undead"].Get(undead[0])

	if !found {
		t.Fatal("derived undead lost its source monster base")
	}

	baseKind, err := base.Get("base_kind_id")

	if err != nil || baseKind == "" {
		t.Fatalf("derived undead lost its source monster base: %v", err)
	}

	summoned, found := g.scripts.Components()["magic.summon"].Get(undead[0])

	if !found {
		t.Fatal("derived undead lost its summon owner")
	}

	sourceID, err := summoned.Get("source_id")

	if err != nil || sourceID != "GOD_YREDELEMNUL" {
		t.Fatalf("derived undead lost source god: %v (%v)", sourceID, err)
	}

	category, err := summoned.Get("source_category")

	if err != nil || category != "gods" {
		t.Fatalf("derived undead lost god category: %v (%v)", category, err)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	again, found := restored.scripts.Components()["magic.summon_undead"].Get(undead[0])

	if !found {
		t.Fatal("restore lost Yredelemnul undead base")
	}

	restoredKind, err := again.Get("base_kind_id")

	if err != nil || restoredKind != baseKind {
		t.Fatalf("restore changed Yredelemnul undead base: %v (%v)", restoredKind, err)
	}

	restoredSummon, found := restored.scripts.Components()["magic.summon"].Get(undead[0])

	if !found {
		t.Fatal("restore lost Yredelemnul undead god ownership")
	}

	restoredSource, err := restoredSummon.Get("source_id")

	if err != nil || restoredSource != sourceID {
		t.Fatalf("restore changed Yredelemnul god source: %v (%v)", restoredSource, err)
	}

	gifts := 0

	for _, entity := range restored.scripts.Components()["magic.summon"].Entities() {
		state, _ := restored.scripts.Components()["magic.summon"].Get(entity)
		source, getErr := state.Get("source_id")

		if getErr != nil {
			t.Fatal(getErr)
		}

		if source != "GOD_YREDELEMNUL" || entity == undead[0] {
			continue
		}

		attitude, getErr := state.Get("attitude")

		if getErr != nil {
			t.Fatal(getErr)
		}

		if attitude == "friendly" {
			gifts++
		}
	}

	if gifts != 1 {
		t.Fatalf("restored Yredelemnul gifts = %d, want 1", gifts)
	}
}
