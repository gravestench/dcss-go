package game

import (
	"fmt"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
)

type pendingCorpse struct {
	MonsterID  string
	Position   ecs.Position
	Appearance int
}

func (g *Game) placeCorpse(drop pendingCorpse) error {
	if _, err := g.catalog.Item("CORPSE_BODY"); err != nil {
		return err
	}
	entity, err := g.world.CreateEntity()
	if err != nil {
		return err
	}
	if _, err := g.stores.Items.Set(entity, ecs.Item{
		KindID:   "CORPSE_BODY",
		Quantity: 1,
	}); err != nil {
		return err
	}
	if _, err := ordinaryAnimal(g.catalog, drop.MonsterID); err != nil {
		return err
	}
	if _, err := g.stores.Corpses.Set(entity, ecs.Corpse{
		MonsterID:  drop.MonsterID,
		Freshness:  monster.FreshestCorpse,
		Appearance: drop.Appearance,
	}); err != nil {
		return err
	}
	if _, err := g.stores.Positions.Set(entity, drop.Position); err != nil {
		return err
	}
	return nil
}

// ageCorpses runs after monster turns at the source's 200-aut boundary.
// Only the active floor ages here. Inactive floors receive one catch-up call
// when the player returns, preserving the skeleton reset after long absences.
func (g *Game) ageCorpses(startAut, endAut Aut) error {
	if endAut < startAut || endAut/monster.CorpseRotIntervalAut == startAut/monster.CorpseRotIntervalAut {
		return nil
	}
	lastTick := startAut / monster.CorpseRotIntervalAut * monster.CorpseRotIntervalAut
	position, found := g.stores.Positions.Get(g.player)
	if !found {
		return fmt.Errorf("player has no position for corpse timer")
	}
	return g.ageCorpsesOnLevel(position.LevelID, int(endAut-lastTick))
}

func (g *Game) ageCorpsesOnLevel(levelID, elapsed int) error {
	for _, entity := range g.stores.Corpses.Entities() {
		corpse, found := g.stores.Corpses.Get(entity)
		item, itemFound := g.stores.Items.Get(entity)
		position, located := g.stores.Positions.Get(entity)
		if !found || !itemFound || !located {
			return fmt.Errorf("corpse %d is not a floor item", entity)
		}
		if position.LevelID != levelID {
			continue
		}
		kind, freshness, appearance, alive, err := monster.AgeCorpse(g.rng, item.KindID, corpse.Freshness, elapsed)
		if err != nil {
			return err
		}
		if !alive {
			if !g.world.DestroyEntity(entity) {
				return fmt.Errorf("corpse %d could not be destroyed", entity)
			}
			continue
		}
		item.KindID = kind
		corpse.Freshness = freshness
		if appearance != 0 {
			corpse.Appearance = appearance
		}
	}
	return nil
}
