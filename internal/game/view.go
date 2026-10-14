package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
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
	X, Y   int
	Glyph  rune
	KindID string
	Name   string
	Role   string
}

type ItemView struct {
	KindID   string
	Name     string
	Class    string
	Quantity int
	Plus     int
	Charges  int
	Ego      string
	Slot     string
}

type View struct {
	LevelID               int
	PlayerX, PlayerY      int
	PlayerDead            bool
	PlayerName            string
	Width, Height         int
	Cells                 []CellView
	Entities              []EntityView
	PlayerHP, PlayerMaxHP int
	PlayerMP, PlayerMaxMP int
	CurrentAut            Aut
	Messages              []string
	Inventory             []ItemView
	CharacterName         string
	Attributes            ecs.Attributes
	Skills                []character.Skill
}

func (g *Game) View() View {
	position, found := g.stores.Positions.Get(g.player)
	if !found {
		return View{}
	}
	level := g.levels[position.LevelID]
	view := View{LevelID: position.LevelID, PlayerX: position.X, PlayerY: position.Y, Width: level.width, Height: len(level.terrain), Cells: make([]CellView, len(level.remembered)), CurrentAut: g.currentAut,
		Messages: append([]string(nil), g.messages...)}
	for i, glyph := range level.remembered {
		switch {
		case g.visibleLevelID == level.ID && i < len(g.visible) && g.visible[i]:
			view.Cells[i] = CellView{Glyph: rune(level.terrain[i/level.width][i%level.width]), State: Visible}
		case glyph != 0:
			view.Cells[i] = CellView{Glyph: rune(glyph), State: Explored}
		}
	}
	if health, ok := g.stores.Health.Get(g.player); ok {
		view.PlayerHP, view.PlayerMaxHP = health.Current, health.Max
		view.PlayerDead = health.Current <= 0
	}
	if magic, ok := g.stores.Magic.Get(g.player); ok {
		view.PlayerMP, view.PlayerMaxMP = magic.Current, magic.Max
	}
	if skills, ok := g.stores.Skills.Get(g.player); ok {
		view.Skills = append([]character.Skill(nil), skills.Entries...)
	}
	if player, ok := g.stores.Players.Get(g.player); ok {
		view.PlayerName = player.Name
		if view.PlayerName == "" {
			view.PlayerName = "Adventurer"
		}
		species, speciesErr := g.catalog.Species(player.SpeciesID)
		job, jobErr := g.catalog.Job(player.JobID)
		if speciesErr == nil && jobErr == nil {
			view.CharacterName = species.Name + " " + job.Name
		}
	}
	if attributes, ok := g.stores.Attributes.Get(g.player); ok {
		view.Attributes = *attributes
	}
	for _, entity := range g.stores.Positions.Entities() {
		location, _ := g.stores.Positions.Get(entity)
		if location.LevelID != position.LevelID {
			continue
		}
		if entity != g.player && (g.visibleLevelID != level.ID || location.Y*level.width+location.X >= len(g.visible) || !g.visible[location.Y*level.width+location.X]) {
			continue
		}
		glyph := rune('?')
		kindID, name, role := "", "", ""
		switch {
		case entity == g.player:
			glyph = '@'
			kindID, name, role = "player", view.PlayerName, "player"
		case g.stores.AI.Has(entity):
			actor, _ := g.stores.Actors.Get(entity)
			kindID, role = actor.KindID, "monster"
			if definition, err := g.catalog.Monster(actor.KindID); err == nil {
				glyph = definition.Glyph
				name = definition.Name
			}
		case g.stores.Items.Has(entity):
			item, _ := g.stores.Items.Get(entity)
			kindID, role = item.KindID, "item"
			if definition, err := g.catalog.Item(item.KindID); err == nil {
				glyph = definition.Glyph
				name = definition.Name
			}
		}
		view.Entities = append(view.Entities, EntityView{ID: uint64(entity), X: location.X, Y: location.Y, Glyph: glyph, KindID: kindID, Name: name, Role: role})
	}
	for _, entity := range g.stores.CarriedBy.Entities() {
		carrier, _ := g.stores.CarriedBy.Get(entity)
		if carrier.Holder != g.player {
			continue
		}
		item, found := g.stores.Items.Get(entity)
		if !found {
			continue
		}
		definition, err := g.catalog.Item(item.KindID)
		if err == nil {
			entry := ItemView{KindID: item.KindID, Name: definition.Name, Class: definition.Class, Quantity: item.Quantity, Plus: item.Plus, Charges: item.Charges, Ego: item.Ego}
			if equipped, found := g.stores.Equipped.Get(entity); found {
				entry.Slot = equipped.Slot
			}
			view.Inventory = append(view.Inventory, entry)
		}
	}
	return view
}
