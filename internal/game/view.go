package game

import (
	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
)

type EntityView struct {
	ID    uint64
	X, Y  int
	Glyph rune
}

type ItemView struct {
	KindID   string
	Name     string
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
	Terrain               []string
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
	view := View{LevelID: position.LevelID, PlayerX: position.X, PlayerY: position.Y, Terrain: append([]string(nil), level.terrain...), CurrentAut: g.currentAut,
		Messages: append([]string(nil), g.messages...)}
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
		glyph := rune('?')
		switch {
		case entity == g.player:
			glyph = '@'
		case g.stores.AI.Has(entity):
			actor, _ := g.stores.Actors.Get(entity)
			if definition, err := g.catalog.Monster(actor.KindID); err == nil {
				glyph = definition.Glyph
			}
		case g.stores.Items.Has(entity):
			item, _ := g.stores.Items.Get(entity)
			if definition, err := g.catalog.Item(item.KindID); err == nil {
				glyph = definition.Glyph
			}
		}
		view.Entities = append(view.Entities, EntityView{ID: uint64(entity), X: location.X, Y: location.Y, Glyph: glyph})
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
			entry := ItemView{KindID: item.KindID, Name: definition.Name, Quantity: item.Quantity, Plus: item.Plus, Charges: item.Charges, Ego: item.Ego}
			if equipped, found := g.stores.Equipped.Get(entity); found {
				entry.Slot = equipped.Slot
			}
			view.Inventory = append(view.Inventory, entry)
		}
	}
	return view
}
