package game

import (
	"github.com/gravestench/akara"
)

// registerSystems composes current Go behavior and Lua-registered behavior
// into one deterministic Akara order. A migrated domain removes its Go entry.
func registerSystems(g *Game) error {
	base, err := collectGoSystems(g)

	if err != nil {
		return err
	}

	for _, system := range g.scripts.Systems() {
		base = append(base, systemSpec{
			name:   system.Name,
			system: system,
			after:  system.After,
			before: system.Before,
		})
	}

	ordered, err := orderSystems(base)

	if err != nil {
		return err
	}

	for _, entry := range ordered {
		if _, err := g.world.AddSystem(entry.system); err != nil {
			return err
		}
	}

	return nil
}

func collectGoSystems(g *Game) ([]systemSpec, error) {
	stores := g.stores

	g.corpseAging = corpseAgingSystem{
		world:     g.world,
		items:     stores.Items,
		corpses:   stores.Corpses,
		positions: stores.Positions,
		catalog:   g.catalog,
		rng:       g.rng,
	}

	g.monsterCatchup = monsterCatchupSystem{
		actors:    stores.Actors,
		health:    stores.Health,
		positions: stores.Positions,
		ai:        stores.AI,
		catalog:   g.catalog,
		rng:       g.rng,
	}

	advancement, err := newAdvancementSystem(g)

	if err != nil {
		return nil, err
	}

	g.advancement = advancement

	entries := []struct {
		name   string
		system akara.System
	}{
		{
			name: "monster.regeneration",
			system: &monsterRegenerationSystem{
				actors:  stores.Actors,
				health:  stores.Health,
				ai:      stores.AI,
				catalog: g.catalog,
				rng:     g.rng,
				turn:    &g.turn,
			},
		},

		{
			name:   "monster.decision",
			system: newMonsterDecisionSystem(g),
		},

		{
			name: "world.stairs",
			system: &stairSystem{
				positions: stores.Positions,
				intents:   stores.Intents,
				levels:    g.levels,
				turn:      &g.turn,
			},
		},

		{
			name: "item.pickup",
			system: &pickupSystem{
				positions: stores.Positions,
				items:     stores.Items,
				corpses:   stores.Corpses,
				carried:   stores.CarriedBy,
				intents:   stores.Intents,
				catalog:   g.catalog,
				turn:      &g.turn,
			},
		},

		{
			name: "item.drop",
			system: &dropSystem{
				items:   stores.Items,
				carried: stores.CarriedBy,
				intents: stores.Intents,
				catalog: g.catalog,
				turn:    &g.turn,
			},
		},

		{
			name: "item.wield",
			system: &wieldSystem{
				items:   stores.Items,
				carried: stores.CarriedBy,
				intents: stores.Intents,
				catalog: g.catalog,
				turn:    &g.turn,
			},
		},

		{
			name: "item.quaff",
			system: &quaffSystem{
				player:    g.player,
				intents:   stores.Intents,
				items:     stores.Items,
				carried:   stores.CarriedBy,
				health:    stores.Health,
				durations: stores.Durations,
				poison:    stores.Poison,
				rng:       g.rng,
				turn:      &g.turn,
			},
		},

		{
			name: "world.doors",
			system: &doorSystem{
				game:    g,
				intents: stores.Intents,
				turn:    &g.turn,
			},
		},

		{
			name:   "attack.spell",
			system: newMonsterSpellSystem(g),
		},

		{
			name:   "world.movement",
			system: newMovementSystem(g),
		},

		{
			name:   "attack.combat",
			system: newCombatSystem(g),
		},

		{
			name:   "status.constriction",
			system: newConstrictSystem(g),
		},

		{
			name:   "actor.death",
			system: newDeathSystem(g),
		},

		{
			name:   "character.training",
			system: newSkillTrainingSystem(g),
		},

		{
			name:   "character.advancement",
			system: advancement,
		},

		{
			name: "status.duration",
			system: &durationSystem{
				player:    g.player,
				durations: stores.Durations,
				rng:       g.rng,
				turn:      &g.turn,
			},
		},

		{
			name: "status.regeneration",
			system: &regenerationSystem{
				player:       g.player,
				health:       stores.Health,
				magic:        stores.Magic,
				regeneration: stores.Regeneration,
				rng:          g.rng,
				turn:         &g.turn,
			},
		},

		{
			name: "status.poison",
			system: &poisonSystem{
				player: g.player,
				health: stores.Health,
				poison: stores.Poison,
				turn:   &g.turn,
			},
		},
	}

	specs := make([]systemSpec, 0, len(entries))

	for _, entry := range entries {
		specs = append(specs, systemSpec{
			name:    entry.name,
			system:  entry.system,
			goOrder: true,
		})
	}

	return specs, nil
}
