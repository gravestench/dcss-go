package save

import (
	"encoding/json"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/terrain"
)

const Version = 18

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
	ID              int            `json:"id"`
	BranchID        string         `json:"branch_id"`
	Cells           [][]terrain.ID `json:"cells"`
	Known           [][]terrain.ID `json:"known"`
	Seen            [][]bool       `json:"seen"`
	DetectedItems   [][]bool       `json:"detected_items"`
	Stairs          []StairRecord  `json:"stairs,omitempty"`
	InitialMonsters int            `json:"initial_monsters,omitempty"`
	InitialActors   int            `json:"initial_actors,omitempty"`
	AwaySinceAut    *int64         `json:"away_since_aut,omitempty"`
}

type StairRecord struct {
	X           int    `json:"x"`
	Y           int    `json:"y"`
	ToLevelID   int    `json:"to_level_id"`
	ToX         int    `json:"to_x"`
	ToY         int    `json:"to_y"`
	Unavailable string `json:"unavailable,omitempty"`
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

	Item      *ecs.Item      `json:"item,omitempty"`
	Corpse    *ecs.Corpse    `json:"corpse,omitempty"`
	CarriedBy *ecs.CarriedBy `json:"carried_by,omitempty"`
	Equipped  *ecs.Equipped  `json:"equipped,omitempty"`

	Dynamic []DynamicComponentRecord `json:"dynamic,omitempty"`
}
