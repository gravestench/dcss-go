package ecs

import "github.com/gravestench/akara"

// Stores contains this run's component handles. It is created with its world.
type Stores struct {
	Positions     *akara.Store[Position]
	Actors        *akara.Store[Actor]
	PlayerTurn    *akara.Store[PlayerTurn]
	MonsterEnergy *akara.Store[MonsterEnergy]
	Health        *akara.Store[Health]
	Magic         *akara.Store[Magic]

	Skills        *akara.Store[Skills]
	SkillTraining *akara.Store[SkillTraining]
	Progression   *akara.Store[Progression]
	Durations     *akara.Store[Durations]
	Poison        *akara.Store[Poison]
	Constricted   *akara.Store[Constricted]
	Regeneration  *akara.Store[Regeneration]
	Combat        *akara.Store[Combatant]
	Players       *akara.Store[PlayerControlled]
	Attributes    *akara.Store[Attributes]
	Equipment     *akara.Store[EquipmentDelay]

	AI        *akara.Store[MonsterAI]
	Followers *akara.Store[BandFollower]

	Items     *akara.Store[Item]
	Corpses   *akara.Store[Corpse]
	CarriedBy *akara.Store[CarriedBy]
	Equipped  *akara.Store[Equipped]

	Intents *akara.Store[Intent]
}

func Register(world *akara.World) Stores {
	return Stores{
		Positions:     akara.Register[Position](world),
		Actors:        akara.Register[Actor](world),
		PlayerTurn:    akara.Register[PlayerTurn](world),
		MonsterEnergy: akara.Register[MonsterEnergy](world),
		Health:        akara.Register[Health](world),
		Magic:         akara.Register[Magic](world),

		Skills:        akara.Register[Skills](world),
		SkillTraining: akara.Register[SkillTraining](world),
		Progression:   akara.Register[Progression](world),
		Durations:     akara.Register[Durations](world),
		Poison:        akara.Register[Poison](world),
		Constricted:   akara.Register[Constricted](world),
		Regeneration:  akara.Register[Regeneration](world),
		Combat:        akara.Register[Combatant](world),
		Players:       akara.Register[PlayerControlled](world),
		Attributes:    akara.Register[Attributes](world),
		Equipment:     akara.Register[EquipmentDelay](world),

		AI:        akara.Register[MonsterAI](world),
		Followers: akara.Register[BandFollower](world),

		Items:     akara.Register[Item](world),
		Corpses:   akara.Register[Corpse](world),
		CarriedBy: akara.Register[CarriedBy](world),
		Equipped:  akara.Register[Equipped](world),

		Intents: akara.Register[Intent](world),
	}
}
