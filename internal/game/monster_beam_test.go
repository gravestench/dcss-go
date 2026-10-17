package game

import (
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
)

func TestMonsterBeamSecondSlotOverlayAndSaveContinuation(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-beam-selection")
	placePlayerInSlugLine(t, g, caster)

	energy, _ := g.stores.MonsterEnergy.Get(caster)
	health, _ := g.stores.Health.Get(g.player)
	beforeHP := health.Current

	energy.Points = 80

	events, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if g.turn.ResolvedIntent != ecs.IntentSpell ||
		health.Current >= beforeHP {
		t.Fatalf("beam cast intent %d, HP %d -> %d, events %+v",
			g.turn.ResolvedIntent, beforeHP, health.Current, events)
	}

	modded := false

	for _, event := range events {
		if strings.Contains(event.Text, "Overlay dart hit.") {
			modded = true
		}
	}

	if !modded {
		t.Fatalf("sparse beam override did not run: %+v", events)
	}

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind:   g.turn.ResolvedIntent,
		ItemID: g.turn.ResolvedItemID,
	}); err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("overridden beam cast changed on save restore")
	}

	for _, current := range []*Game{g, loaded} {
		ready, _ := current.stores.MonsterEnergy.Get(caster)

		ready.Points = 80
	}

	liveEvents, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	loadedEvents, err := loaded.runAction(caster, ecs.Intent{},
		10, "monster")

	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(liveEvents, loadedEvents) ||
		!reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("beam continuation diverged after save restore")
	}
}

func TestFlashFrozenStatusSurvivesSaveRestore(t *testing.T) {
	g, caster, rules := moddedEndoplasmGame(t,
		"testdata/monster-beam-freeze")
	placePlayerInSlugLine(t, g, caster)

	for attempt := 0; attempt < 30; attempt++ {
		energy, _ := g.stores.MonsterEnergy.Get(caster)

		energy.Points = 80

		if _, err := g.runAction(caster, ecs.Intent{}, 10,
			"monster"); err != nil {
			t.Fatal(err)
		}

		if g.scripts.Components()["zap.flash_frozen"].Has(g.player) {
			break
		}
	}

	frozen := g.scripts.Components()["zap.flash_frozen"]

	if frozen == nil || !frozen.Has(g.player) {
		t.Fatal("monster Flash Freeze did not apply ECS status")
	}

	snapshot := g.Snapshot()
	loaded, err := RestoreWithRules(snapshot, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !loaded.scripts.Components()["zap.flash_frozen"].Has(g.player) ||
		!reflect.DeepEqual(snapshot, loaded.Snapshot()) {
		t.Fatal("saved flash-frozen status changed on restore")
	}
}

func TestMonsterStoneArrowBlocksWithWornAmulet(t *testing.T) {
	g, caster, _ := moddedEndoplasmGame(t,
		"testdata/monster-beam-reflection")
	placePlayerInSlugLine(t, g, caster)

	baseSH := g.View().PlayerSH
	amulet := addCarriedArmour(t, g, "AMU_REFLECTION")

	if _, err := g.stores.Equipped.Set(amulet, ecs.Equipped{
		Slot: "amulet",
	}); err != nil {
		t.Fatal(err)
	}

	if g.View().PlayerSH <= baseSH {
		t.Fatal("reflection amulet did not increase player shield")
	}

	blocks, _ := g.stores.Combat.Get(g.player)
	casterPosition, _ := g.stores.Positions.Get(caster)
	originX, originY := casterPosition.X, casterPosition.Y
	blockedSpell := false
	spellCasts := 0
	otherBlocks := 0

	for attempt := 0; attempt < 100; attempt++ {
		if err := g.levels[casterPosition.LevelID].MoveActor(
			caster, originX, originY); err != nil {
			t.Fatal(err)
		}

		energy, _ := g.stores.MonsterEnergy.Get(caster)
		health, _ := g.stores.Health.Get(g.player)
		before := blocks.ShieldBlocks

		energy.Points = 80
		health.Current = health.Max

		_, err := g.runAction(caster, ecs.Intent{}, 10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		if g.turn.ResolvedIntent == ecs.IntentSpell {
			spellCasts++
		} else if blocks.ShieldBlocks > before {
			otherBlocks++
		}

		if blocks.ShieldBlocks > before &&
			g.turn.ResolvedIntent == ecs.IntentSpell {
			blockedSpell = true
			break
		}
	}

	if !blockedSpell {
		t.Fatalf("Stone Arrow block absent: casts=%d other-blocks=%d",
			spellCasts, otherBlocks)
	}
}
