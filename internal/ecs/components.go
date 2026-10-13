package ecs

import "github.com/gravestench/akara"

// Position is the authoritative location of an entity on a level.
type Position struct {
	LevelID int
	X       int
	Y       int
}

// Actor stores the source-defined kind and logical scheduling state.
type Actor struct {
	KindID  string
	Speed   int
	NextAut int64
}

type Health struct {
	Current int
	Max     int
}

type Combatant struct {
	BaseDamage int
}

type PlayerControlled struct {
	SpeciesID string
	JobID     string
}

type MonsterAI struct {
	Behavior string
}

type Item struct {
	KindID   string
	Quantity int
}

// CarriedBy and Position are mutually exclusive on an item.
type CarriedBy struct {
	Holder akara.Entity
}

type IntentKind uint8

const (
	IntentMove IntentKind = iota + 1
	IntentMelee
	IntentPickup
	IntentUpstairs
	IntentDownstairs
	IntentWait
)

type Intent struct {
	Kind IntentKind
	DX   int
	DY   int
}
