package game

import (
	"reflect"
	"testing"
)

// The ordinary command runner lets a confused Elyvilon worshipper purify,
// then saves the patron's timed HP/MP bonus without a Go ability branch.
func TestElyvilonPurificationAndVigourRestore(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}
	g.world.DestroyEntity(rat)

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_ELYVILON",
			"piety":  int64(200),
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	magic, found := g.stores.Magic.Get(g.player)
	if !found {
		t.Fatal("player has no MP")
	}
	magic.Max = 20
	magic.Current = 20
	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["zap.player_confusion"].Set(
		g.player,
		map[string]any{"remaining_aut": int64(1000)},
	)
	if err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 12 &&
		g.scripts.Components()["zap.player_confusion"].Has(g.player); attempt++ {
		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_ELYVILON_PURIFICATION",
		})
		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("Purification spent %d aut, events %+v: %v",
				result.Spent, result.Events, stepErr)
		}
	}

	if g.scripts.Components()["zap.player_confusion"].Has(g.player) {
		t.Fatal("Purification did not clear confusion")
	}
	// Heal Self uses the same command route; lower HP through the ECS
	// store so the ability's normal full-health preflight accepts it.
	health, found := g.stores.Health.Get(g.player)
	if !found {
		t.Fatal("player has no HP")
	}
	health.Current = 1
	if _, err := g.stores.Health.Set(g.player, *health); err != nil {
		t.Fatal(err)
	}
	for attempt := 0; attempt < 15; attempt++ {
		magic, _ = g.stores.Magic.Get(g.player)
		magic.Max = 20
		magic.Current = 20
		if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
			t.Fatal(err)
		}
		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_ELYVILON_HEAL_SELF",
		})
		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("Heal Self spent %d aut, events %+v: %v",
				result.Spent, result.Events, stepErr)
		}
		health, _ = g.stores.Health.Get(g.player)
		if health.Current > 1 {
			break
		}
	}
	if health.Current <= 1 {
		t.Fatal("Heal Self never restored HP")
	}

	for attempt := 0; attempt < 30 &&
		!g.scripts.Components()["religion.elyvilon_vigour"].Has(g.player); attempt++ {
		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_ELYVILON_DIVINE_VIGOUR",
		})
		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("Divine Vigour spent %d aut, events %+v: %v",
				result.Spent, result.Events, stepErr)
		}
	}

	if !g.scripts.Components()["religion.elyvilon_vigour"].Has(g.player) {
		t.Fatal("Divine Vigour never succeeded")
	}

	restored, err := Restore(g.Snapshot())
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()

	if !restored.scripts.Components()["religion.elyvilon_vigour"].Has(
		restored.player) {
		t.Fatal("restored Divine Vigour lost its saved timer")
	}
}

// Pacification through the real ability command awards XP once, stores
// neutral real allegiance, and passes the normal Go save validator.
func TestElyvilonHealOtherPacifiesAndRestores(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(rat, 2, 1); err != nil {
		t.Fatal(err)
	}

	_, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_ELYVILON",
			"piety":  int64(200),
		},
	)
	if err != nil {
		t.Fatal(err)
	}
	magic, found := g.stores.Magic.Get(g.player)
	if !found {
		t.Fatal("player has no MP")
	}
	baseMax := magic.Max
	magic.Max = 20
	magic.Current = 20
	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	for attempt := 0; attempt < 25 &&
		!g.scripts.Components()["religion.elyvilon_pacified"].Has(rat); attempt++ {
		position, found := g.stores.Positions.Get(rat)
		player, playerFound := g.stores.Positions.Get(g.player)

		if !found || !playerFound {
			t.Fatal("pacification target left the active floor")
		}

		result, stepErr := g.Step(Command{
			Kind:      CommandAbility,
			AbilityID: "ABIL_ELYVILON_HEAL_OTHER",
			DX:        position.X - player.X,
			DY:        position.Y - player.Y,
		})
		if stepErr != nil || result.Spent != 10 {
			t.Fatalf("Heal Other spent %d aut, events %+v: %v",
				result.Spent, result.Events, stepErr)
		}
	}

	if !g.scripts.Components()["religion.elyvilon_pacified"].Has(rat) {
		t.Fatal("Heal Other did not pacify the rat")
	}

	progress, found := g.stores.Progression.Get(g.player)
	if !found || progress.TotalXP != 1 {
		t.Fatalf("pacification XP = %+v", progress)
	}
	magic, _ = g.stores.Magic.Get(g.player)
	magic.Max = baseMax
	magic.Current = baseMax
	if _, err := g.stores.Magic.Set(g.player, *magic); err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())
	if err != nil {
		t.Fatal(err)
	}
	defer restored.Close()

	if !restored.scripts.Components()["religion.elyvilon_pacified"].Has(
		rat) {
		t.Fatal("restored rat lost its pacified allegiance")
	}
}

// Twin conversion creates two independent once-only pacification markers.
// The Lua rule test exercises the conversion itself; this checks that the
// ordinary game save keeps more than one marker without inventing XP.
func TestElyvilonPairedPacificationStateRestores(t *testing.T) {
	g := newPopulatedTestGame(t, 41)
	actors := g.stores.AI.Entities()
	if len(actors) < 2 {
		t.Fatal("population has fewer than two monsters")
	}
	markers := g.scripts.Components()["religion.elyvilon_pacified"]

	for _, actor := range actors[:2] {
		if _, err := markers.Set(actor, map[string]any{
			"pacified": true,
		}); err != nil {
			t.Fatal(err)
		}
	}

	before := g.Snapshot()
	loaded, err := Restore(before)
	if err != nil {
		t.Fatal(err)
	}
	defer loaded.Close()

	for _, actor := range actors[:2] {
		if !loaded.scripts.Components()["religion.elyvilon_pacified"].Has(actor) {
			t.Fatalf("pacified actor %d lost its marker", actor)
		}
	}
	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("paired pacification state changed on restore")
	}
}
