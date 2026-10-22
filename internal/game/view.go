package game

import (
	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/terrain"
	"crawl/internal/vault"
	"fmt"
)

type CellState uint8

const (
	Unknown CellState = iota
	Explored
	Visible
)

type CellView struct {
	Glyph        rune
	State        CellState
	DetectedItem bool
	ColorID      string
}

type EntityView struct {
	ID            uint64
	X             int
	Y             int
	Glyph         rune
	KindID        string
	Name          string
	Role          string
	ColorID       string
	AnimatedColor bool
}

type ItemView struct {
	ID     uint64
	KindID string
	Name   string
	Class  string

	Quantity int
	Slot     string
}

type SpellView struct {
	ID         string
	InLibrary  bool
	KnownSlot  int
	LetterSlot int
}

type View struct {
	LevelID    int
	BranchID   string
	LocalDepth int
	Width      int
	Height     int
	Cells      []CellView
	Clouds     []EntityView
	Entities   []EntityView

	PlayerX    int
	PlayerY    int
	PlayerDead bool
	Outcome    string
	PlayerName string

	PlayerHP     int
	PlayerMaxHP  int
	PlayerMP     int
	PlayerMaxMP  int
	PlayerAC     int
	PlayerEV     int
	PlayerSH     int
	Gold         int64
	DefenseKnown bool
	GodName      string
	PietyStars   string
	Penance      int

	CharacterName           string
	SpeciesID               string
	SpeciesName             string
	Attributes              ecs.Attributes
	Skills                  []character.Skill
	SkillTraining           ecs.SkillTraining
	SkillTrainingAdjustable bool
	SkillPercent            map[string]int
	ExperienceLevel         int
	NextLevelPercent        int
	PendingStatLevel        int
	PendingSkillExperience  int
	MightAut                int
	HasteAut                int
	PoisonAmountScaled      int
	Constricted             bool

	Inventory              []ItemView
	Spells                 []SpellView
	LastSpellID            string
	LearningSpellID        string
	LearningRemaining      int
	VampireRitualRemaining int
	EquipmentDelay         *ecs.EquipmentDelay
	CurrentAut             Aut
	Messages               []string
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
		LevelID:    position.LevelID,
		BranchID:   level.BranchID,
		LocalDepth: level.LocalDepth,
		PlayerX:    position.X,
		PlayerY:    position.Y,

		Width:  level.width,
		Height: len(level.terrain),
		Cells:  make([]CellView, len(level.remembered)),

		CurrentAut: g.currentAut,
		Messages:   append([]string(nil), g.messages...),
	}

	g.fillTerrainView(&view, level)
	g.fillVaultView(&view, level)
	g.fillCloudView(&view, level)
	g.fillPlayerView(&view)
	g.fillEntityView(&view, level, position.LevelID)
	g.fillInventoryView(&view)
	g.fillSpellView(&view)

	outcome, err := g.outcome()

	if err != nil {
		panic(err)
	}

	view.Outcome = outcome

	return view
}

func (g *Game) fillVaultView(view *View, level *Level) {
	for _, record := range level.vaultRecords {
		if record.Overridden {
			continue
		}

		index := record.Y*level.width + record.X

		if g.visibleLevelID != level.ID ||
			index < 0 ||
			index >= len(g.visible) ||
			!g.visible[index] {
			continue
		}

		if record.Kind == vault.KindSourceFeature &&
			record.Identity == string(terrain.Altar) &&
			!record.Pending {
			g.fillAltarView(view, record)
			continue
		}

		if !record.Pending || !vaultVisibleKind(record.Kind) {
			continue
		}

		glyph := '?'

		if record.SourceGlyph != "" {
			glyph = []rune(record.SourceGlyph)[0]
		}

		view.Entities = append(view.Entities, EntityView{
			X:      record.X,
			Y:      record.Y,
			Glyph:  glyph,
			KindID: string(record.Kind),
			Name:   record.Identity + " (unavailable)",
			Role:   "vault_pending",
		})
	}
}

// Saved Temple altar IDs name the visible source feature through Lua. The
// generic terrain owns movement and glyph; presentation owns divine names.
func (g *Game) fillAltarView(view *View, record vault.Record) {
	for _, argument := range record.Arguments {
		if argument.Name != "god_id" {
			continue
		}

		presentation := g.mustPresentationPolicy("presentation.altar",
			map[string]any{"god_id": argument.String})

		view.Entities = append(view.Entities, EntityView{
			X:      record.X,
			Y:      record.Y,
			Glyph:  rune(presentation["glyph"].(int64)),
			KindID: argument.String,
			Name:   presentation["name"].(string),
			Role:   "altar",
		})

		return
	}
}

func vaultVisibleKind(kind vault.Kind) bool {
	switch kind {
	case vault.KindSourceFeature, vault.KindFeature,
		vault.KindItem, vault.KindMonster, vault.KindMarker:
		return true
	}

	return false
}

func (g *Game) fillCloudView(view *View, level *Level) {
	for _, cloud := range g.cloudsOnLevel(level.ID) {
		index := cloud.y*level.width + cloud.x

		if g.visibleLevelID != level.ID ||
			index < 0 ||
			index >= len(g.visible) ||
			!g.visible[index] {
			continue
		}

		presentation := g.mustPresentationPolicy("presentation.entity", map[string]any{
			"role":    "cloud",
			"kind_id": cloud.kindID,
		})

		view.Clouds = append(view.Clouds, EntityView{
			X:             cloud.x,
			Y:             cloud.y,
			Glyph:         rune(presentation["glyph"].(int64)),
			KindID:        cloud.kindID,
			Name:          presentation["name"].(string),
			Role:          "cloud",
			ColorID:       presentation["color_id"].(string),
			AnimatedColor: presentation["animated_color"].(bool),
		})
	}
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
	detectedGlyph := rune(0)

	for i, feature := range level.remembered {
		switch {
		case g.visibleLevelID == level.ID &&
			i < len(g.visible) &&
			g.visible[i]:
			colour, _ := level.CellColour(i%level.width, i/level.width)

			view.Cells[i] = CellView{
				Glyph:   terrain.Glyph(level.terrain[i/level.width][i%level.width]),
				State:   Visible,
				ColorID: colour,
			}

		case feature != terrain.Unseen:
			view.Cells[i] = CellView{
				Glyph: terrain.Glyph(feature),
				State: Explored,
			}
		}

		if level.detectedItems[i] {
			if detectedGlyph == 0 {
				presentation := g.mustPresentationPolicy("presentation.detected_item", nil)
				detectedGlyph = rune(presentation["glyph"].(int64))
			}

			view.Cells[i] = CellView{
				Glyph:        detectedGlyph,
				State:        Explored,
				DetectedItem: true,
			}
		}
	}
}

func (g *Game) fillPlayerView(view *View) {
	player, hasPlayer := g.stores.Players.Get(g.player)
	worship := g.mustPresentationPolicy("presentation.religion", nil)

	view.GodName = worship["god_name"].(string)
	view.PietyStars = worship["piety_stars"].(string)
	view.Penance = int(worship["penance"].(int64))

	if store := g.scripts.Components()["character.wallet"]; store != nil {
		if state, ok := store.Get(g.player); ok {
			gold, err := state.Get("gold")

			if err != nil {
				panic(err)
			}

			view.Gold = gold.(int64)
		}
	}

	if health, ok := g.stores.Health.Get(g.player); ok {
		view.PlayerHP = health.Current
		view.PlayerMaxHP = health.Max
		view.PlayerDead = health.Current <= 0
	}

	if magic, ok := g.stores.Magic.Get(g.player); ok {
		view.PlayerMP = magic.Current
		view.PlayerMaxMP = magic.Max
	}

	if state, ok := g.scripts.Components()["character.vampire"].Get(g.player); ok {
		remaining, err := state.Get("ritual_remaining_aut")

		if err != nil {
			panic(err)
		}

		view.VampireRitualRemaining = int(remaining.(int64))
	}

	if store := g.scripts.Components()["character.potion_experience"]; store != nil {
		if state, ok := store.Get(g.player); ok {
			pending, err := state.Get("pending_skill_xp")

			if err != nil {
				panic(err)
			}

			view.PendingSkillExperience = int(pending.(int64))
		}
	}

	if skills, ok := g.stores.Skills.Get(g.player); ok {
		view.Skills = append([]character.Skill(nil), skills.Entries...)
	}

	if training, ok := g.stores.SkillTraining.Get(g.player); ok {
		view.SkillTraining = training.Clone()

		controls := g.mustPresentationPolicy("character.training_controls", nil)

		view.SkillTrainingAdjustable = controls["adjustable"].(bool)

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

	attributes := g.mustPresentationPolicy("character.attributes", map[string]any{})

	view.Attributes = ecs.Attributes{
		Strength:     int(attributes["strength"].(int64)),
		Intelligence: int(attributes["intelligence"].(int64)),
		Dexterity:    int(attributes["dexterity"].(int64)),
	}

	defense := g.mustPresentationPolicy("presentation.defense", map[string]any{})

	view.PlayerAC = int(defense["ac"].(int64))
	view.PlayerEV = int(defense["ev"].(int64))
	view.PlayerSH = int(defense["sh"].(int64))
	view.DefenseKnown = true
}

func (g *Game) fillEntityView(view *View, level *Level, levelID int) {
	trapStore := g.scripts.Components()["world.trap"]

	for _, entity := range g.stores.Positions.Entities() {
		location, _ := g.stores.Positions.Get(entity)

		if location.LevelID != levelID {
			continue
		}

		index := location.Y*level.width + location.X
		visible := g.visibleLevelID == level.ID &&
			index < len(g.visible) &&
			g.visible[index]
		trapState, isTrap := trapStore.Get(entity)
		knownTrap := isTrap && view.Cells[index].State != Unknown

		if entity != g.player &&
			!visible &&
			!g.stores.AI.Has(entity) &&
			!knownTrap {
			continue
		}

		kindID, role := "", ""
		input := map[string]any{}

		switch {
		case entity == g.player:
			role = "player"
			input["player_name"] = view.PlayerName

		case g.stores.AI.Has(entity):
			perception := g.mustPresentationPolicy(
				"character.monster_perception",
				map[string]any{
					"monster":      entity,
					"cell_visible": visible,
					"cell_known":   view.Cells[index].State != Unknown,
				},
			)

			mode := perception["mode"].(string)

			if mode == "unseen" {
				continue
			}

			if mode == "detected" {
				role = "disturbance"
				break
			}

			actor, _ := g.stores.Actors.Get(entity)
			kindID, role = actor.KindID, "monster"
			input["monster_entity_id"] = uint64(entity)

		case g.stores.Items.Has(entity):
			item, _ := g.stores.Items.Get(entity)
			kindID, role = item.KindID, "item"

			if corpse, found := g.stores.Corpses.Get(entity); found {
				input["corpse_monster_id"] = corpse.MonsterID
			}

		case isTrap:
			revealed, err := trapState.Get("revealed")

			if err != nil {
				panic(err)
			}

			if !revealed.(bool) || !knownTrap {
				continue
			}

			kind, err := trapState.Get("kind_id")

			if err != nil {
				panic(err)
			}

			kindID, role = kind.(string), "trap"
			input["color_id"] = "LIGHTGREY"

			if !visible {
				input["color_id"] = "DARKGREY"
			}

		default:
			continue
		}

		input["role"] = role
		input["kind_id"] = kindID

		if role == "item" {
			input["item_entity_id"] = uint64(entity)
		}

		presentation := g.mustPresentationPolicy("presentation.entity", input)

		entityID := uint64(entity)

		if role == "disturbance" {
			entityID = 0
		}

		view.Entities = append(view.Entities, EntityView{
			ID:            entityID,
			X:             location.X,
			Y:             location.Y,
			Glyph:         rune(presentation["glyph"].(int64)),
			KindID:        presentation["kind_id"].(string),
			Name:          presentation["name"].(string),
			Role:          presentation["role"].(string),
			ColorID:       presentation["color_id"].(string),
			AnimatedColor: presentation["animated_color"].(bool),
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
			"item_entity_id": uint64(entity),
			"kind_id":        item.KindID,
			"quantity":       item.Quantity,
			"slot":           slot,
		})

		view.Inventory = append(view.Inventory, ItemView{
			ID:       uint64(entity),
			KindID:   presentation["kind_id"].(string),
			Name:     presentation["name"].(string),
			Class:    presentation["class"].(string),
			Quantity: item.Quantity,
			Slot:     slot,
		})
	}
}
