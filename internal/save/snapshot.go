package save

import "dcrawl-go/internal/ecs"

const Version = 2

type Snapshot struct {
	Version        int               `json:"version"`
	SourceRevision string            `json:"source_revision"`
	PlayerID       uint64            `json:"player_id"`
	CurrentAut     int64             `json:"current_aut"`
	Seed           uint64            `json:"seed"`
	RNG            map[string]uint64 `json:"rng"`
	Levels         []LevelRecord     `json:"levels"`
	Entities       []EntityRecord    `json:"entities"`
	Messages       []string          `json:"messages"`
}

type LevelRecord struct {
	ID   int      `json:"id"`
	Rows []string `json:"rows"`
}

type EntityRecord struct {
	ID         uint64                `json:"id"`
	Position   *ecs.Position         `json:"position,omitempty"`
	Actor      *ecs.Actor            `json:"actor,omitempty"`
	Health     *ecs.Health           `json:"health,omitempty"`
	Combatant  *ecs.Combatant        `json:"combatant,omitempty"`
	Player     *ecs.PlayerControlled `json:"player,omitempty"`
	Attributes *ecs.Attributes       `json:"attributes,omitempty"`
	AI         *ecs.MonsterAI        `json:"ai,omitempty"`
	Item       *ecs.Item             `json:"item,omitempty"`
	CarriedBy  *ecs.CarriedBy        `json:"carried_by,omitempty"`
}
