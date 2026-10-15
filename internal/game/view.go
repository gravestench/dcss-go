package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/terrain"
	"fmt"
)

type CellState uint8

const (
	Unknown CellState = iota
	Explored
	Visible
)

type CellView struct {
	Glyph rune
	State CellState
}

type EntityView struct {
	ID     uint64
	X      int
	Y      int
	Glyph  rune
	KindID string
	Name   string
	Role   string
}

type ItemView struct {
	ID     uint64
	KindID string
	Name   string
	Class  string

	Quantity int
	Plus     int
	Charges  int
	Ego      string
	Slot     string
}

type SpellView struct {
	ID         string
	InLibrary  bool
	KnownSlot  int
	LetterSlot int
}

type View struct {
	LevelID  int
	Width    int
	Height   int
	Cells    []CellView
	Entities []EntityView

	PlayerX    int
	PlayerY    int
	PlayerDead bool
	PlayerName string

	PlayerHP     int
	PlayerMaxHP  int
	PlayerMP     int
	PlayerMaxMP  int
	PlayerAC     int
	PlayerEV     int
	PlayerSH     int
	DefenseKnown bool

	CharacterName      string
	SpeciesID          string
	SpeciesName        string
	Attributes         ecs.Attributes
	Skills             []character.Skill
	SkillTraining      ecs.SkillTraining
	SkillPercent       map[string]int
	ExperienceLevel    int
	NextLevelPercent   int
	PendingStatLevel   int
	MightAut           int
	HasteAut           int
	PoisonAmountScaled int
	Constricted        bool

	Inventory         []ItemView
	Spells            []SpellView
	LastSpellID       string
	LearningSpellID   string
	LearningRemaining int
	EquipmentDelay    *ecs.EquipmentDelay
	CurrentAut        Aut
	Messages          []string
}

func (g *Game) View() (view View) {
	defer func() {
		if failure := recover(); failure != nil {
			problem, ok := failure.(error)

			if !ok {
				panic(failure)
			}

			view.Messages = append(
				view.Messages,
				fmt.Sprintf("Lua presentation error: %v", problem),
			)
		}
	}()

	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return View{}
	}

	level := g.levels[position.LevelID]
	view = View{
		LevelID: position.LevelID,
		PlayerX: position.X,
		PlayerY: position.Y,

		Width:  level.width,
		Height: len(level.terrain),
		Cells:  make([]CellView, len(level.remembered)),

		CurrentAut: g.currentAut,
		Messages:   append([]string(nil), g.messages...),
	}

	g.fillTerrainView(&view, level)
	g.fillPlayerView(&view)
	g.fillEntityView(&view, level, position.LevelID)
	g.fillInventoryView(&view)
	g.fillSpellView(&view)

	return view
}

// PresentationPolicy runs a pure, named screen decision against this game's
// effective Lua ruleset. Renderers pass plain values and draw its result.
func (g *Game) PresentationPolicy(name string, input map[string]any) (map[string]any, error) {
	return g.scripts.Policy(name, input)
}

func (g *Game) mustPresentationPolicy(name string, input map[string]any) map[string]any {
	result, err := g.PresentationPolicy(name, input)

	if err != nil {
		panic(err)
	}

	return result
}

func (g *Game) fillTerrainView(view *View, level *Level) {
	for i, feature := range level.remembered {
		switch {
		case g.visibleLevelID == level.ID &&
			i < len(g.visible) &&
			g.visible[i]:
			view.Cells[i] = CellView{
				Glyph: terrain.Glyph(level.terrain[i/level.width][i%level.width]),
				State: Visible,
			}

		case feature != terrain.Unseen:
			view.Cells[i] = CellView{
				Glyph: terrain.Glyph(feature),
				State: Explored,
			}
		}
	}
}

func (g *Game) fillPlayerView(view *View) {
	player, hasPlayer := g.stores.Players.Get(g.player)

	if health, ok := g.stores.Health.Get(g.player); ok {
		view.PlayerHP = health.Current
		view.PlayerMaxHP = health.Max
		view.PlayerDead = health.Current <= 0
	}

	if magic, ok := g.stores.Magic.Get(g.player); ok {
		view.PlayerMP = magic.Current
		view.PlayerMaxMP = magic.Max
	}

	if skills, ok := g.stores.Skills.Get(g.player); ok {
		view.Skills = append([]character.Skill(nil), skills.Entries...)
	}

	if training, ok := g.stores.SkillTraining.Get(g.player); ok {
		view.SkillTraining = training.Clone()

		percent := g.mustPresentationPolicy("character.training_percent", map[string]any{})

		view.SkillPercent = make(map[string]int, len(percent))

		for id, value := range percent {
			view.SkillPercent[id] = int(value.(int64))
		}
	}

	if progression, ok := g.stores.Progression.Get(g.player); ok && hasPlayer {
		identity := g.mustPresentationPolicy("presentation.player", map[string]any{
			"name":       player.Name,
			"species_id": player.SpeciesID,
			"job_id":     player.JobID,
			"total_xp":   progression.TotalXP,
			"level":      progression.Level,
		})

		view.PlayerName = identity["player_name"].(string)
		view.SpeciesName = identity["species_name"].(string)
		view.CharacterName = identity["character_name"].(string)
		view.ExperienceLevel = progression.Level
		view.NextLevelPercent = int(identity["next_level_percent"].(int64))
		view.PendingStatLevel = progression.PendingStatLevel
	}

	if durations, ok := g.stores.Durations.Get(g.player); ok {
		view.MightAut = durations.MightAut
		view.HasteAut = durations.HasteAut
	}

	if poison, ok := g.stores.Poison.Get(g.player); ok {
		view.PoisonAmountScaled = poison.AmountScaled
	}

	view.Constricted = g.stores.Constricted.Has(g.player)

	if delay, ok := g.stores.Equipment.Get(g.player); ok {
		copy := *delay

		view.EquipmentDelay = &copy
	}

	if hasPlayer {
		view.SpeciesID = player.SpeciesID
	}

	if attributes, ok := g.stores.Attributes.Get(g.player); ok {
		view.Attributes = *attributes
	}

	defense := g.mustPresentationPolicy("presentation.defense", map[string]any{})

	view.PlayerAC = int(defense["ac"].(int64))
	view.PlayerEV = int(defense["ev"].(int64))
	view.PlayerSH = int(defense["sh"].(int64))
	view.DefenseKnown = true
}

func (g *Game) fillEntityView(view *View, level *Level, levelID int) {
	for _, entity := range g.stores.Positions.Entities() {
		location, _ := g.stores.Positions.Get(entity)

		if location.LevelID != levelID {
			continue
		}

		index := location.Y*level.width + location.X
		visible := g.visibleLevelID == level.ID &&
			index < len(g.visible) &&
			g.visible[index]

		if entity != g.player && !visible {
			continue
		}

		kindID, role := "", ""
		input := map[string]any{}

		switch {
		case entity == g.player:
			role = "player"
			input["player_name"] = view.PlayerName

		case g.stores.AI.Has(entity):
			actor, _ := g.stores.Actors.Get(entity)
			kindID, role = actor.KindID, "monster"

		case g.stores.Items.Has(entity):
			item, _ := g.stores.Items.Get(entity)
			kindID, role = item.KindID, "item"

			if corpse, found := g.stores.Corpses.Get(entity); found {
				input["corpse_monster_id"] = corpse.MonsterID
			}
		}

		input["role"] = role
		input["kind_id"] = kindID

		presentation := g.mustPresentationPolicy("presentation.entity", input)

		view.Entities = append(view.Entities, EntityView{
			ID:     uint64(entity),
			X:      location.X,
			Y:      location.Y,
			Glyph:  rune(presentation["glyph"].(int64)),
			KindID: presentation["kind_id"].(string),
			Name:   presentation["name"].(string),
			Role:   presentation["role"].(string),
		})
	}
}

func (g *Game) fillInventoryView(view *View) {
	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)

		if carrier.Holder != g.player {
			continue
		}

		item, found := g.stores.Items.Get(entity)

		if !found {
			continue
		}

		slot := ""

		if equipped, found := g.stores.Equipped.Get(entity); found {
			slot = equipped.Slot
		}

		presentation := g.mustPresentationPolicy("presentation.inventory_item", map[string]any{
			"kind_id":  item.KindID,
			"quantity": item.Quantity,
			"plus":     item.Plus,
			"charges":  item.Charges,
			"ego":      item.Ego,
			"slot":     slot,
		})

		view.Inventory = append(view.Inventory, ItemView{
			ID:       uint64(entity),
			KindID:   presentation["kind_id"].(string),
			Name:     presentation["name"].(string),
			Class:    presentation["class"].(string),
			Quantity: item.Quantity,
			Plus:     item.Plus,
			Charges:  item.Charges,
			Ego:      item.Ego,
			Slot:     slot,
		})
	}
}
