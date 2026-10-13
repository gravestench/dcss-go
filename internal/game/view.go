package game

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
	return view
}
