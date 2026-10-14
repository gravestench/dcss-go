package ecs

import "github.com/gravestench/akara"

// Stores contains this run's component handles. It is created with its world.
type Stores struct {
	Positions    *akara.Store[Position]
	Actors       *akara.Store[Actor]
	Health       *akara.Store[Health]
	Magic        *akara.Store[Magic]
	Skills       *akara.Store[Skills]
	Progression  *akara.Store[Progression]
	Durations    *akara.Store[Durations]
	Regeneration *akara.Store[Regeneration]
	Combat       *akara.Store[Combatant]
	Players      *akara.Store[PlayerControlled]
	Attributes   *akara.Store[Attributes]
	AI           *akara.Store[MonsterAI]
	Items        *akara.Store[Item]
	CarriedBy    *akara.Store[CarriedBy]
	Equipped     *akara.Store[Equipped]
	Intents      *akara.Store[Intent]
}

func Register(world *akara.World) Stores {
	return Stores{
		Positions:    akara.Register[Position](world),
		Actors:       akara.Register[Actor](world),
		Health:       akara.Register[Health](world),
		Magic:        akara.Register[Magic](world),
		Skills:       akara.Register[Skills](world),
		Progression:  akara.Register[Progression](world),
		Durations:    akara.Register[Durations](world),
		Regeneration: akara.Register[Regeneration](world),
		Combat:       akara.Register[Combatant](world),
		Players:      akara.Register[PlayerControlled](world),
		Attributes:   akara.Register[Attributes](world),
		AI:           akara.Register[MonsterAI](world),
		Items:        akara.Register[Item](world),
		CarriedBy:    akara.Register[CarriedBy](world),
		Equipped:     akara.Register[Equipped](world),
		Intents:      akara.Register[Intent](world),
	}
}
