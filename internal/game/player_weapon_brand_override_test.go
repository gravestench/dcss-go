package game

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
)

func TestPlayerBrandSamePathOverlayChangesRulesetAndHit(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/player-flame-mod")

	if err != nil {
		t.Fatal(err)
	}

	if bundled.Hash() == modded.Hash() {
		t.Fatal("player brand override left ruleset identity unchanged")
	}

	g, err := newScenarioWithRules(1, startChoice{
		SpeciesID: "SP_HUMAN",
		JobID:     "JOB_FIGHTER",
	}, "WPN_RAPIER", "Tester", ordinaryMonsterScenarioID, modded)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	weapon, _ := g.stores.Items.Get(playerMeleeWeapon(t, g))

	weapon.Ego = "SPWPN_FLAMING"

	ratHealth, _ := g.stores.Health.Get(ratID(t, g))

	ratHealth.Max = 1000
	ratHealth.Current = 1000

	for attempt := 0; attempt < 60; attempt++ {
		result, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		})

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range result.Events {
			if strings.Contains(event.Text, "modded player flame") {
				return
			}
		}
	}

	t.Fatal("overridden player flame module never controlled a hit")
}
