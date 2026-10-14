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
	X      int
	Y      int
	Glyph  rune
	KindID string
	Name   string
	Role   string
}

type ItemView struct {
	ID       uint64
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
	LevelID          int
	PlayerX          int
	PlayerY          int
	PlayerDead       bool
	PlayerName       string
	Width            int
	Height           int
	Cells            []CellView
	Entities         []EntityView
	PlayerHP         int
	PlayerMaxHP      int
	PlayerMP         int
	PlayerMaxMP      int
	PlayerAC         int
	PlayerEV         int
	PlayerSH         int
	DefenseKnown     bool
	CurrentAut       Aut
	Messages         []string
	Inventory        []ItemView
	CharacterName    string
	Attributes       ecs.Attributes
	Skills           []character.Skill
	ExperienceLevel  int
	NextLevelPercent int
	PendingStatLevel int
	MightAut         int
}

func (g *Game) View() View {
	position, found := g.stores.Positions.Get(g.player)

	if !found {
		return View{}
	}

	level := g.levels[position.LevelID]
	view := View{
		LevelID:    position.LevelID,
		PlayerX:    position.X,
		PlayerY:    position.Y,
		Width:      level.width,
		Height:     len(level.terrain),
		Cells:      make([]CellView, len(level.remembered)),
		CurrentAut: g.currentAut,
		Messages:   append([]string(nil), g.messages...),
	}

	for i, glyph := range level.remembered {
		switch {
		case g.visibleLevelID == level.ID && i < len(g.visible) && g.visible[i]:
			view.Cells[i] = CellView{
				Glyph: rune(level.terrain[i/level.width][i%level.width]),
				State: Visible,
			}
		case glyph != 0:
			view.Cells[i] = CellView{
				Glyph: rune(glyph),
				State: Explored,
			}
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

	if skills, ok := g.stores.Skills.Get(g.player); ok {
		view.Skills = append([]character.Skill(nil), skills.Entries...)
	}

	if progression, ok := g.stores.Progression.Get(g.player); ok {
		if percent, err := character.HumanLevelProgress(
			progression.TotalXP, progression.Level,
		); err == nil {
			view.ExperienceLevel = progression.Level
			view.NextLevelPercent = percent
			view.PendingStatLevel = progression.PendingStatLevel
		}
	}

	if durations, ok := g.stores.Durations.Get(g.player); ok {
		view.MightAut = durations.MightAut
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

	if defense, err := newPlayerCombat(g).defense(); err == nil {
		view.PlayerAC = defense.AC
		view.PlayerEV = defense.EV
		view.PlayerSH = defense.ShieldClass / 2
		view.DefenseKnown = true
	}

	for _, entity := range g.stores.Positions.Entities() {
		location, _ := g.stores.Positions.Get(entity)

		if location.LevelID != position.LevelID {
			continue
		}

		index := location.Y*level.width + location.X
		visible := g.visibleLevelID == level.ID && index < len(g.visible) && g.visible[index]

		if entity != g.player && !visible {
			continue
		}

		glyph := rune('?')
		kindID, name, role := "", "", ""

		switch {
		case entity == g.player:
			glyph = '@'
			kindID = "player"
			name = view.PlayerName
			role = "player"
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

				if corpse, found := g.stores.Corpses.Get(entity); found {
					if source, err := g.catalog.Monster(corpse.MonsterID); err == nil {
						name = source.Name + " " + definition.Name
					}
				}
			}
		}

		view.Entities = append(view.Entities, EntityView{
			ID:     uint64(entity),
			X:      location.X,
			Y:      location.Y,
			Glyph:  glyph,
			KindID: kindID,
			Name:   name,
			Role:   role,
		})
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
			entry := ItemView{
				ID:       uint64(entity),
				KindID:   item.KindID,
				Name:     definition.Name,
				Class:    definition.Class,
				Quantity: item.Quantity,
				Plus:     item.Plus,
				Charges:  item.Charges,
				Ego:      item.Ego,
			}

			if equipped, found := g.stores.Equipped.Get(entity); found {
				entry.Slot = equipped.Slot
			}

			view.Inventory = append(view.Inventory, entry)
		}
	}

	return view
}
