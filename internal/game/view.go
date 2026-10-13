package game

import "dcrawl-go/internal/ecs"

type EntityView struct {
	ID    uint64
	X, Y  int
	Glyph rune
}

type ItemView struct {
	KindID   string
	Name     string
	Quantity int
}

type View struct {
	LevelID               int
	Terrain               []string
	Entities              []EntityView
	PlayerHP, PlayerMaxHP int
	CurrentAut            Aut
	Messages              []string
	Inventory             []ItemView
	CharacterName         string
	Attributes            ecs.Attributes
}

func (g *Game) View() View {
	position, found := g.stores.Positions.Get(g.player)
	if !found {
		return View{}
	}
	level := g.levels[position.LevelID]
	view := View{LevelID: position.LevelID, Terrain: append([]string(nil), level.terrain...), CurrentAut: g.currentAut,
		Messages: append([]string(nil), g.messages...)}
	if health, ok := g.stores.Health.Get(g.player); ok {
		view.PlayerHP, view.PlayerMaxHP = health.Current, health.Max
	}
	if player, ok := g.stores.Players.Get(g.player); ok {
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
			view.Inventory = append(view.Inventory, ItemView{KindID: item.KindID, Name: definition.Name, Quantity: item.Quantity})
		}
	}
	return view
}
