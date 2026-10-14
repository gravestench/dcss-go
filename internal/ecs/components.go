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

// Progression owns earned XP and the applied level. A pending stat choice
// holds the next level until the player chooses, as in DCSS level_change.
type Progression struct {
	TotalXP          int
	Level            int
	PendingStatLevel int
}

// Durations owns temporary player effects in action-time units (aut).
type Durations struct {
	MightAut int
}

// Regeneration owns the player's fractional HP and MP recovery counters.
type Regeneration struct {
	HPProgress int
	MPProgress int
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
	Behavior       string
	TargetX        int
	TargetY        int
	MemoryUntilAut int64
}

type Item struct {
	KindID   string
	Quantity int
	Plus     int
	Charges  int
	Ego      string
}

// Corpse records source freshness and appearance for a floor corpse or skeleton.
type Corpse struct {
	MonsterID  string
	Freshness  int
	Appearance int
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
