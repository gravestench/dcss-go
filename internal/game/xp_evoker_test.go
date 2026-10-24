package game

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestHornOfGeryonSpendsSharedXPCharge(t *testing.T) {
	g := newStepGame(t)
	horn := carriedTestWand(t, g, "MISC_HORN_OF_GERYON", 0)
	beforeAut := g.View().CurrentAut

	result, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: horn,
	})
	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 || g.View().CurrentAut != beforeAut+10 {
		t.Fatalf("horn use spent %d aut", result.Spent)
	}

	for _, item := range g.View().Inventory {
		if item.KindID == "MISC_HORN_OF_GERYON" &&
			!strings.Contains(item.Name, "0/1") {
			t.Fatalf("spent horn has wrong charge label: %q", item.Name)
		}
	}

	second, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: horn,
	})
	if err != nil {
		t.Fatal(err)
	}

	if second.Spent != 0 || g.View().CurrentAut != beforeAut+10 {
		t.Fatal("inert horn spent time")
	}
}

func TestXPEvokerDebtSurvivesSaveAndRejectsForgedSubtype(t *testing.T) {
	g := newStepGame(t)
	horn := carriedTestWand(t, g, "MISC_HORN_OF_GERYON", 0)

	if _, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: horn,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()

	if _, err := restored.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: horn,
	}); err != nil {
		t.Fatal(err)
	}

	for entityIndex := range snapshot.Entities {
		if snapshot.Entities[entityIndex].ID != snapshot.PlayerID {
			continue
		}

		for partIndex := range snapshot.Entities[entityIndex].Dynamic {
			part := &snapshot.Entities[entityIndex].Dynamic[partIndex]
			if part.Schema == "character.xp_evokers" {
				part.Values["debt"] = json.RawMessage(
					`{"MISC_FAKE_EVOKER":10}`)
			}
		}
	}

	forged, err := Restore(snapshot)
	if forged != nil {
		forged.Close()
	}
	if err == nil || !strings.Contains(err.Error(), "invalid XP evoker debt") {
		t.Fatalf("forged evoker debt was accepted: %v", err)
	}
}

func TestLightningRodCopiesShareFourXPCharges(t *testing.T) {
	g := newStepGame(t)
	first := carriedTestWand(t, g, "MISC_LIGHTNING_ROD", 0)
	_ = carriedTestWand(t, g, "MISC_LIGHTNING_ROD", 0)
	beforeAut := g.View().CurrentAut

	result, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: first,
		DX:     1,
	})
	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 || g.View().CurrentAut != beforeAut+10 {
		t.Fatalf("lightning rod use spent %d aut", result.Spent)
	}

	count := 0
	for _, item := range g.View().Inventory {
		if item.KindID == "MISC_LIGHTNING_ROD" {
			count++
			if !strings.Contains(item.Name, "3/4") {
				t.Fatalf("rod copies have different charges: %q", item.Name)
			}
		}
	}

	if count != 2 {
		t.Fatalf("expected two rods, got %d", count)
	}
}

func TestBoxOfBeastsCreatesSavedMutantBeast(t *testing.T) {
	g := newStepGame(t)
	box := carriedTestWand(t, g, "MISC_BOX_OF_BEASTS", 0)

	result, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: box,
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.Spent != 10 {
		t.Fatalf("box spent %d aut", result.Spent)
	}

	found := false
	for _, actor := range g.View().Entities {
		if actor.KindID == "MONS_MUTANT_BEAST" {
			found = true
		}
	}
	if !found {
		t.Fatal("box did not create a mutant beast")
	}

	restored, err := Restore(g.Snapshot())
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()
}

func TestRemainingXPEvokersResolveAndRestore(t *testing.T) {
	tests := []struct {
		name string
		dx   int
	}{
		{name: "MISC_PHIAL_OF_FLOODS", dx: 1},
		{name: "MISC_TIN_OF_TREMORSTONES"},
		{name: "MISC_CONDENSER_VANE"},
		{name: "MISC_XOMS_CHESSBOARD"},
	}

	for _, scenario := range tests {
		t.Run(scenario.name, func(t *testing.T) {
			g := newStepGame(t)
			item := carriedTestWand(t, g, scenario.name, 0)

			result, err := g.Step(Command{
				Kind:   CommandEvokeItem,
				ItemID: item,
				DX:     scenario.dx,
				Forced: true,
			})
			if err != nil {
				t.Fatal(err)
			}
			if result.Spent != 10 {
				t.Fatalf("evocation spent %d aut", result.Spent)
			}

			restored, err := Restore(g.Snapshot())
			if err != nil {
				t.Fatal(err)
			}
			defer restored.Close()
		})
	}
}

func TestAutomaticXPEvokersAskBeforeBlindUse(t *testing.T) {
	for _, kind := range []string{
		"MISC_TIN_OF_TREMORSTONES",
		"MISC_CONDENSER_VANE",
		"MISC_XOMS_CHESSBOARD",
	} {
		t.Run(kind, func(t *testing.T) {
			g := newStepGame(t)
			defer g.Close()
			item := carriedTestWand(t, g, kind, 0)

			for _, monster := range g.stores.MonsterEnergy.Entities() {
				if health, found := g.stores.Health.Get(monster); found {
					health.Current = 0
				}
			}

			before := g.currentAut
			command := Command{Kind: CommandEvokeItem, ItemID: item}
			result, err := g.Step(command)
			if err != nil {
				t.Fatal(err)
			}
			if result.Spent != 0 || result.Confirmation == "" ||
				g.currentAut != before {
				t.Fatalf("blind use did not ask freely: %+v", result)
			}

			command.Forced = true
			result, err = g.Step(command)
			if err != nil {
				t.Fatal(err)
			}
			if result.Spent != 10 {
				t.Fatalf("confirmed use spent %d aut", result.Spent)
			}
		})
	}
}

func TestPhialHitsMonsterAndSavesFloodedTerrain(t *testing.T) {
	g := newStepGame(t)
	worm := spawnWormForTest(t, g, 1)
	health, _ := g.stores.Health.Get(worm)
	health.Current = 100
	health.Max = 100
	player, _ := g.stores.Positions.Get(g.player)
	target, _ := g.stores.Positions.Get(worm)
	item := carriedTestWand(t, g, "MISC_PHIAL_OF_FLOODS", 0)

	result, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: item,
		DX:     target.X - player.X,
		DY:     target.Y - player.Y,
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.Spent != 10 || health.Current >= 100 {
		t.Fatalf("phial did not strike worm: %+v, health %d",
			result, health.Current)
	}

	state, ok := g.scripts.Components()["world.temporary_terrain"]
	if !ok {
		t.Fatal("temporary terrain schema is missing")
	}
	flooded := false
	for _, marker := range g.world.Entities() {
		flooded = flooded || state.Has(marker)
	}
	if !flooded {
		t.Fatal("phial did not flood any terrain")
	}
}

func TestPhantomMirrorCreatesDrainedClone(t *testing.T) {
	g := newStepGame(t)
	worm := spawnWormForTest(t, g, 1)
	player, _ := g.stores.Positions.Get(g.player)
	target, _ := g.stores.Positions.Get(worm)
	item := carriedTestWand(t, g, "MISC_PHANTOM_MIRROR", 0)

	result, err := g.Step(Command{
		Kind:   CommandEvokeItem,
		ItemID: item,
		DX:     target.X - player.X,
		DY:     target.Y - player.Y,
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.Spent != 10 {
		t.Fatalf("mirror spent %d aut", result.Spent)
	}

	clones := g.scripts.Components()["magic.summon_mirror"].Entities()
	if len(clones) != 1 ||
		!g.scripts.Components()["magic.monster_drained"].Has(clones[0]) {
		t.Fatalf("mirror made %d clones without source drain", len(clones))
	}

	for _, carried := range g.View().Inventory {
		if carried.KindID == "MISC_PHANTOM_MIRROR" &&
			!strings.Contains(carried.Name, "0/1") {
			t.Fatalf("mirror charge was not spent: %q", carried.Name)
		}
	}
}

func TestAutomaticXPEvokersActOnNearbyMonster(t *testing.T) {
	for _, scenario := range []struct {
		kind  string
		label string
	}{
		{kind: "MISC_TIN_OF_TREMORSTONES", label: "1/2"},
		{kind: "MISC_CONDENSER_VANE", label: "0/1"},
		{kind: "MISC_XOMS_CHESSBOARD", label: "14/15"},
	} {
		t.Run(scenario.kind, func(t *testing.T) {
			g := newStepGame(t)
			_ = spawnWormForTest(t, g, 1)
			item := carriedTestWand(t, g, scenario.kind, 0)

			result, err := g.Step(Command{
				Kind:   CommandEvokeItem,
				ItemID: item,
				Forced: true,
			})
			if err != nil {
				t.Fatal(err)
			}
			if result.Spent != 10 {
				t.Fatalf("evocation spent %d aut", result.Spent)
			}

			charged := false
			for _, carried := range g.View().Inventory {
				if carried.KindID == scenario.kind {
					charged = strings.Contains(carried.Name, scenario.label)
				}
			}
			if !charged {
				t.Fatalf("%s did not spend its source XP charge", scenario.kind)
			}

			if scenario.kind == "MISC_CONDENSER_VANE" &&
				len(g.scripts.Components()["world.cloud"].Entities()) == 0 {
				t.Fatal("condenser created no cloud around the worm")
			}
		})
	}
}
