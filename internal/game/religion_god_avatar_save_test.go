package game

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// Lasting wrath keeps an inert god source through save/restore, then
// releases it after the final status no longer names that source.
func TestGodAvatarLastingSpellSurvivesRestore(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.avatar_spell", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	avatarStore := g.scripts.Components()["religion.avatar_source"]

	if len(avatarStore.Entities()) != 1 {
		t.Fatalf("god avatar sources = %d, want 1",
			len(avatarStore.Entities()))
	}

	if !g.scripts.Components()["zap.sticky_flame"].Has(g.player) {
		t.Fatal("god spell did not leave a saved burn")
	}

	forged := g.Snapshot()

	for entityIndex := range forged.Entities {
		for partIndex := range forged.Entities[entityIndex].Dynamic {
			part := &forged.Entities[entityIndex].Dynamic[partIndex]

			if part.Schema == "religion.avatar_source" {
				part.Values["god_id"] = json.RawMessage(`"GOD_XOM"`)
			}
		}
	}

	invalid, err := RestoreWithRules(forged, rules, RestorePolicy{})

	if invalid != nil {
		defer invalid.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "invalid saved god avatar source") {
		t.Fatalf("forged god source restore error = %v", err)
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	avatarStore = restored.scripts.Components()["religion.avatar_source"]

	if len(avatarStore.Entities()) != 1 ||
		!restored.scripts.Components()["zap.sticky_flame"].Has(restored.player) {
		t.Fatal("restore lost the god source or its lasting burn")
	}

	restored.scripts.Components()["zap.sticky_flame"].Remove(restored.player)

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	if len(avatarStore.Entities()) != 0 {
		t.Fatal("spent god source remained after cleanup")
	}

	if _, err := restored.scripts.Policy("test.avatar_ball_lightning", nil); err != nil {
		t.Fatal(err)
	}

	if err := restored.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if len(avatarStore.Entities()) != 1 ||
		len(restored.scripts.Components()["magic.summon"].Entities()) == 0 {
		t.Fatal("god ball lightning lacks a saved source or summons")
	}

	summoned, err := RestoreWithRules(restored.Snapshot(),
		rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer summoned.Close()

	if len(summoned.scripts.Components()["religion.avatar_source"].Entities()) != 1 ||
		len(summoned.scripts.Components()["magic.summon"].Entities()) == 0 {
		t.Fatal("restore lost god-owned ball lightning")
	}
}

// Mephitic Cloud keeps Vehumet's source after the casting actor is gone.
// Restoring the level must keep both the cloud and its god attribution.
func TestGodAvatarMephiticCloudSurvivesRestore(t *testing.T) {
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

	if _, err := g.scripts.Policy("test.avatar_mephitic_cloud", nil); err != nil {
		t.Fatal(err)
	}

	if err := g.scripts.ApplyPending(); err != nil {
		t.Fatal(err)
	}

	if len(g.scripts.Components()["religion.avatar_source"].Entities()) != 1 ||
		len(g.scripts.Components()["world.cloud"].Entities()) == 0 {
		t.Fatal("god-cast Mephitic Cloud lacks a saved source or cloud")
	}

	restored, err := RestoreWithRules(g.Snapshot(), rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if len(restored.scripts.Components()["religion.avatar_source"].Entities()) != 1 ||
		len(restored.scripts.Components()["world.cloud"].Entities()) == 0 {
		t.Fatal("restore lost Vehumet's god source or noxious cloud")
	}
}
