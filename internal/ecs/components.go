package ecs

import (
	"dcrawl-go/internal/character"
	"github.com/gravestench/akara"
)

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

// Magic is the player's current and maximum MP.
type Magic struct {
	Current int
	Max     int
}

// Skills records level and training points for each starting skill.
type Skills struct {
	Entries []character.Skill
}

type Combatant struct {
	ShieldBlocks int
}

type PlayerControlled struct {
	Name             string `json:"Name,omitempty"`
	SpeciesID        string
	JobID            string
	StartingWeaponID string
}

type Attributes struct {
	Strength     int
	Intelligence int
	Dexterity    int
}

type MonsterAI struct {
	Behavior string
}

type Item struct {
	KindID   string
	Quantity int
	Plus     int
	Charges  int
	Ego      string
}

// CarriedBy and Position are mutually exclusive on an item.
type CarriedBy struct {
	Holder akara.Entity
}

// Equipped records an inventory item's active slot; CarriedBy owns it.
type Equipped struct {
	Slot string
}

type IntentKind uint8

const (
	IntentMove IntentKind = iota + 1
	IntentMelee
	IntentPickup
	IntentUpstairs
	IntentDownstairs
	IntentWait
	IntentQuaff
)

type Intent struct {
	Kind   IntentKind
	DX     int
	DY     int
	ItemID akara.Entity
}
