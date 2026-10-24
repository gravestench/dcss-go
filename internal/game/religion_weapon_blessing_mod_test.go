package game

import (
	"strings"
	"testing"

	"crawl/internal/modfs"
)

// A mod replaces one god file while retaining the shared item transaction.
// The source ruleset hash records that this run is no longer bundled DCSS.
func TestSamePathDivineBlessingOverride(t *testing.T) {
	bundled, err := modfs.Load()

	if err != nil {
		t.Fatal(err)
	}

	modded, err := modfs.Load("testdata/divine-blessing-mod")

	if err != nil {
		t.Fatal(err)
	}

	if bundled.Hash() == modded.Hash() {
		t.Fatal("same-path divine mod retained bundled hash")
	}

	g, err := newScenarioWithRules(
		1,
		startChoice{
			SpeciesID: "SP_HUMAN",
			JobID:     "JOB_FIGHTER",
		},
		"WPN_LONG_SWORD",
		"Mod tester",
		ordinaryMonsterScenarioID,
		modded,
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	_, err = g.scripts.Components()["religion.worship"].Set(g.player,
		map[string]any{
			"god_id": "GOD_LUGONU",
			"piety":  int64(200),
		})

	if err != nil {
		t.Fatal(err)
	}

	command := Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_LUGONU_BLESS_WEAPON",
	}

	selection, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if selection.Selection == nil || len(selection.Selection.Options) == 0 {
		t.Fatalf("modded blessing selection = %+v", selection)
	}

	command.TargetID = selection.Selection.Options[0].ID

	confirmation, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	if !strings.HasPrefix(confirmation.Confirmation, "Bless ") {
		t.Fatalf("modded confirmation = %+v", confirmation)
	}

	command.Forced = true

	result, err := g.Step(command)

	if err != nil {
		t.Fatal(err)
	}

	for _, event := range result.Events {
		if event.Text == "Modded distortion blessing complete." {
			return
		}
	}

	t.Fatal("same-path blessing override did not resolve")
}
