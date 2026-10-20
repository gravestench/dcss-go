package save

import (
	"encoding/json"

	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
)

const Version = 33

type Snapshot struct {
	Version        int               `json:"version"`
	ScenarioID     string            `json:"scenario_id,omitempty"`
	RulesetHash    string            `json:"ruleset_hash"`
	LuaDialect     string            `json:"lua_dialect"`
	RulesetFiles   []RulesetFile     `json:"ruleset_files,omitempty"`
	RulesetChanges []string          `json:"ruleset_changes,omitempty"`
	LuaSchemas     []LuaSchemaRecord `json:"lua_schemas,omitempty"`

	PlayerID   uint64            `json:"player_id"`
	CurrentAut int64             `json:"current_aut"`
	Seed       uint64            `json:"seed"`
	RNG        map[string]uint64 `json:"rng"`

	Levels   []LevelRecord  `json:"levels"`
	Entities []EntityRecord `json:"entities"`
	Messages []string       `json:"messages"`

	// Generated runs persist their once-chosen branch graph, including
	// entrances on parent floors that have not yet been generated.
	BranchSchedule *BranchScheduleRecord `json:"branch_schedule,omitempty"`
	TemplePlan     *TemplePlanRecord     `json:"temple_plan,omitempty"`
}

// TemplePlanRecord fixes the authored map and god identities before the
// player reaches Temple. Lua policy validates its meaning on restore.
type TemplePlanRecord struct {
	MapID            string                `json:"map_id"`
	AltarCount       int                   `json:"altar_count"`
	MainGodIDs       []string              `json:"main_god_ids"`
	OverflowGodIDs   []string              `json:"overflow_god_ids"`
	OverflowSchedule []OverflowGroupRecord `json:"overflow_schedule"`
}

// OverflowGroupRecord fixes one altar group's gods and Dungeon depth before
// the floor is generated. Map selection remains a Lua generation decision.
type OverflowGroupRecord struct {
	Depth  int      `json:"depth"`
	GodIDs []string `json:"god_ids"`
}

type BranchScheduleRecord struct {
	WaterBranchID  string              `json:"water_branch_id"`
	PoisonBranchID string              `json:"poison_branch_id"`
	Entries        []BranchEntryRecord `json:"entries"`
}

type BranchEntryRecord struct {
	BranchID    string `json:"branch_id"`
	ParentID    string `json:"parent_id"`
	ParentDepth int    `json:"parent_depth"`
}

type RulesetFile struct {
	Path   string `json:"path"`
	SHA256 string `json:"sha256"`
}

type LuaSchemaRecord struct {
	Name    string `json:"name"`
	Version uint32 `json:"version"`
}

type DynamicComponentRecord struct {
	Schema string                     `json:"schema"`
	Values map[string]json.RawMessage `json:"values"`
}

type LevelRecord struct {
	ID              int               `json:"id"`
	BranchID        string            `json:"branch_id"`
	LocalDepth      int               `json:"local_depth"`
	Cells           [][]terrain.ID    `json:"cells"`
	Known           [][]terrain.ID    `json:"known"`
	Seen            [][]bool          `json:"seen"`
	DetectedItems   [][]bool          `json:"detected_items"`
	Stairs          []StairRecord     `json:"stairs,omitempty"`
	InitialMonsters int               `json:"initial_monsters,omitempty"`
	InitialActors   int               `json:"initial_actors,omitempty"`
	SpawnExclusions []PointRecord     `json:"spawn_exclusions,omitempty"`
	AwaySinceAut    *int64            `json:"away_since_aut,omitempty"`
	VaultID         string            `json:"vault_id,omitempty"`
	VaultIDs        []string          `json:"vault_ids,omitempty"`
	VaultRecords    []vault.Record    `json:"vault_records,omitempty"`
	ShoalsTide      *ShoalsTideRecord `json:"shoals_tide,omitempty"`
}

// PointRecord preserves level-local generation masks across save and load.
type PointRecord struct {
	X int `json:"x"`
	Y int `json:"y"`
}

// ShoalsTideRecord keeps the authored elevation separate from the current
// water feature. A returning player can resume the same tide after a save.
type ShoalsTideRecord struct {
	Heights  [][]int `json:"heights"`
	Height   int     `json:"height"`
	Velocity int     `json:"velocity"`
	LastAut  int64   `json:"last_aut"`
}

type StairRecord struct {
	X              int    `json:"x"`
	Y              int    `json:"y"`
	ToLevelID      int    `json:"to_level_id"`
	ToX            int    `json:"to_x"`
	ToY            int    `json:"to_y"`
	Pending        bool   `json:"pending,omitempty"`
	Unavailable    string `json:"unavailable,omitempty"`
	TargetBranchID string `json:"target_branch_id,omitempty"`
	SourceFeature  string `json:"source_feature,omitempty"`
}

type EntityRecord struct {
	ID            uint64             `json:"id"`
	Position      *ecs.Position      `json:"position,omitempty"`
	Actor         *ecs.Actor         `json:"actor,omitempty"`
	PlayerTurn    *ecs.PlayerTurn    `json:"player_turn,omitempty"`
	MonsterEnergy *ecs.MonsterEnergy `json:"monster_energy,omitempty"`
	Health        *ecs.Health        `json:"health,omitempty"`
	Magic         *ecs.Magic         `json:"magic,omitempty"`

	Skills        *ecs.Skills           `json:"skills,omitempty"`
	SkillTraining *ecs.SkillTraining    `json:"skill_training,omitempty"`
	Progression   *ecs.Progression      `json:"progression,omitempty"`
	Durations     *ecs.Durations        `json:"durations,omitempty"`
	Poison        *ecs.Poison           `json:"poison,omitempty"`
	Constricted   *ecs.Constricted      `json:"constricted,omitempty"`
	Regeneration  *ecs.Regeneration     `json:"regeneration,omitempty"`
	Combatant     *ecs.Combatant        `json:"combatant,omitempty"`
	Player        *ecs.PlayerControlled `json:"player,omitempty"`
	Attributes    *ecs.Attributes       `json:"attributes,omitempty"`
	Equipment     *ecs.EquipmentDelay   `json:"equipment_delay,omitempty"`

	AI           *ecs.MonsterAI    `json:"ai,omitempty"`
	BandFollower *ecs.BandFollower `json:"band_follower,omitempty"`

	Item       *ecs.Item       `json:"item,omitempty"`
	Corpse     *ecs.Corpse     `json:"corpse,omitempty"`
	CarriedBy  *ecs.CarriedBy  `json:"carried_by,omitempty"`
	ReservedBy *ecs.ReservedBy `json:"reserved_by,omitempty"`
	Equipped   *ecs.Equipped   `json:"equipped,omitempty"`

	Dynamic []DynamicComponentRecord `json:"dynamic,omitempty"`
}
