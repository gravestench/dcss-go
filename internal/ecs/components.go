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

// Actor stores source-defined identity and base speed.
type Actor struct {
	KindID string
	Speed  int
}

// PlayerTurn owns the next logical action time for the player.
type PlayerTurn struct {
	NextAut int64
}

// MonsterEnergy is the source's speed_increment for one live monster.
type MonsterEnergy struct {
	Points int
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

// Skills records the player's authoritative skill levels and points.
type Skills struct {
	Entries []character.Skill
}

// SkillTrainingSetting controls whether a skill receives earned experience.
type SkillTrainingSetting struct {
	ID      string
	Enabled bool
	Focused bool
}

// SkillTraining owns unspent XP and the recent practice used to divide it.
// The two queues retain their order so a restored run makes the same choices.
type SkillTraining struct {
	AvailableXP int
	SpentXP     int
	CostLevel   int
	Manual      bool

	Settings       []SkillTrainingSetting
	RecentPractice []string
	RecentAll      []string
}

func (training SkillTraining) Clone() SkillTraining {
	training.Settings = append([]SkillTrainingSetting(nil), training.Settings...)
	training.RecentPractice = append([]string(nil), training.RecentPractice...)
	training.RecentAll = append([]string(nil), training.RecentAll...)

	return training
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
	HasteAut int
}

// Poison is the remaining damage carried by one affected actor. The source
// identifies the attacker even after that monster dies or changes floors.
type Poison struct {
	AmountScaled    int
	SourceMonsterID string
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
	Behavior          string
	TargetX           int
	TargetY           int
	MemoryUntilAut    int64
	BatRetreatActions int
}

// BandFollower keeps the original leader identity even after that leader
// dies. AI only follows the leader while it remains a live actor nearby.
type BandFollower struct {
	Leader akara.Entity
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

// EquipmentDelay keeps an interrupted wear or removal action on the player.
// Remaining counts future ten-aut turns in the current phase.
type EquipmentDelay struct {
	ItemID    akara.Entity
	OldItemID akara.Entity
	Slot      string
	Phase     string
	Remaining int
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
	IntentOpenDoor
	IntentCloseDoor
	IntentDrop
	IntentWield
)

type Intent struct {
	Kind     IntentKind
	DX       int
	DY       int
	ItemID   akara.Entity
	Quantity int
}
