package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
)

// A real tome cast creates source living-spell actors. Their saved custom
// book then executes through ordinary AI and dismisses them after casting.
func TestWalkingTomeLivingSpellCastAfterRestore(t *testing.T) {
	game, caster, rules := moddedEndoplasmGame(t, "")
	actor, found := game.stores.Actors.Get(caster)

	if !found {
		t.Fatal("generated caster has no actor")
	}

	actor.KindID = "MONS_DIVINE_TOME"

	placePlayerInSlugLine(t, game, caster)

	energy, _ := game.stores.MonsterEnergy.Get(caster)

	energy.Points = 80

	if _, err := game.runAction(caster, ecs.Intent{}, 10,
		"monster"); err != nil {
		t.Fatal(err)
	}

	if game.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatalf("tome intent = %d, want spell",
			game.turn.ResolvedIntent)
	}

	store := game.scripts.Components()["magic.summon_living_spell"]
	actors := store.Entities()

	if len(actors) < 2 || len(actors) > 3 {
		t.Fatalf("tome made %d living spells, want 2-3",
			len(actors))
	}

	for _, entity := range actors {
		state, _ := store.Get(entity)
		spell, _ := state.Get("spell_id")

		if spell != "SPELL_SMITING" {
			t.Fatalf("living spell = %s, want Smiting", spell)
		}
	}

	// The initial corridor placement can put a living spell around a bend.
	// Give its own actor a clear target lane before saving the action state.
	placePlayerInSlugLine(t, game, actors[0])

	livingAI, _ := game.stores.AI.Get(actors[0])
	playerPosition, _ := game.stores.Positions.Get(game.player)

	livingAI.Behavior = "seek"
	livingAI.TargetX = playerPosition.X
	livingAI.TargetY = playerPosition.Y

	// This test promotes a generated endoplasm to a tome for one cast.
	// Restore's generated-Dungeon roster still requires the original kind;
	// the living actor's saved custom spell must survive that owner change.
	actor.KindID = "MONS_ENDOPLASM"

	if err := game.scheduler.Spend(caster, ecs.Intent{
		Kind: game.turn.ResolvedIntent,
	}); err != nil {
		t.Fatal(err)
	}

	before := game.Snapshot()
	loaded, err := RestoreWithRules(before, rules, RestorePolicy{})

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if !reflect.DeepEqual(before, loaded.Snapshot()) {
		t.Fatal("living spell changed during restore")
	}

	for _, current := range []*Game{game, loaded} {
		events, err := current.runAction(actors[0], ecs.Intent{},
			10, "monster")

		if err != nil {
			t.Fatal(err)
		}

		cast := false

		for _, event := range events {
			if strings.Contains(event.Text,
				"Divine power smites the target") {
				cast = true
			}
		}

		if !cast {
			t.Fatalf("living spell did not cast Smiting: %+v",
				events)
		}

		if current.scripts.Components()["magic.summon_living_spell"].Has(
			actors[0]) {
			t.Fatal("living spell survived completed cast")
		}
	}

	if !reflect.DeepEqual(game.Snapshot(), loaded.Snapshot()) {
		t.Fatal("living spell action diverged after restore")
	}
}
