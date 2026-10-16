package game

import (
	"reflect"
	"testing"

	"dcrawl-go/internal/save"
)

func savedActiveComponent(snapshot save.Snapshot, entityID uint64,
	schema string) bool {
	for _, entity := range snapshot.Entities {
		if entity.ID != entityID {
			continue
		}

		for _, component := range entity.Dynamic {
			if component.Schema == schema {
				return string(component.Values["active"]) == "true"
			}
		}
	}

	return false
}

func TestJewelleryAttunementAndAcrobatSurviveRestore(t *testing.T) {
	g := newStepGame(t)
	removeFixtureRat(t, g)
	regeneration := addCarriedArmour(t, g, "AMU_REGENERATION")

	if _, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(regeneration),
	}); err != nil {
		t.Fatal(err)
	}

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandContinueEquipment}); err != nil {
			t.Fatal(err)
		}
	}

	snapshot := g.Snapshot()

	if !savedActiveComponent(snapshot, uint64(regeneration),
		"item.jewellery_attunement") {
		t.Fatal("worn regeneration amulet has no saved attunement")
	}

	loaded, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("jewellery attunement changed after restore")
	}

	loaded.Close()

	acrobat := addCarriedArmour(t, g, "AMU_ACROBAT")

	if _, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(acrobat),
	}); err != nil {
		t.Fatal(err)
	}

	for turn := 0; turn < 9; turn++ {
		if _, err := g.Step(Command{Kind: CommandContinueEquipment}); err != nil {
			t.Fatal(err)
		}
	}

	if !g.stores.Equipped.Has(acrobat) {
		t.Fatal("acrobat amulet did not finish equipping")
	}

	baseEV := g.View().PlayerEV
	wait, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if wait.Spent == 0 || wait.View.PlayerEV != baseEV+15 {
		t.Fatalf("acrobat wait spent=%d EV=%d base=%d",
			wait.Spent, wait.View.PlayerEV, baseEV)
	}

	snapshot = g.Snapshot()

	if !savedActiveComponent(snapshot, snapshot.PlayerID,
		"character.jewellery_acrobat") {
		t.Fatal("acrobat wait has no saved action window")
	}

	loaded, err = Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("acrobat action window changed after restore")
	}
}

func TestReflectorWearingStateSurvivesRestore(t *testing.T) {
	g := newStepGame(t)
	removeFixtureRat(t, g)
	baseline := g.View().PlayerSH
	amulet := addCarriedArmour(t, g, "AMU_REFLECTION")

	if _, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(amulet),
	}); err != nil {
		t.Fatal(err)
	}

	for turn := 0; turn < 4; turn++ {
		if _, err := g.Step(Command{Kind: CommandContinueEquipment}); err != nil {
			t.Fatal(err)
		}
	}

	if !g.stores.Equipped.Has(amulet) || g.View().PlayerSH <= baseline {
		t.Fatal("reflector did not increase the worn player's shield")
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) ||
		restored.View().PlayerSH != g.View().PlayerSH {
		t.Fatal("reflector wearing state or shield changed after restore")
	}
}
