package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
)

const ordinaryAnimalScenarioID = "fixed-dungeon-rat-quokka-v1"

func isOrdinaryAnimal(id string) bool { return id == "MONS_RAT" || id == "MONS_QUOKKA" }

func (g *Game) ordinaryAnimal(id string) (content.MonsterDef, error) {
	if !isOrdinaryAnimal(id) {
		return content.MonsterDef{}, fmt.Errorf("unsupported ordinary animal %s", id)
	}
	definition, err := g.catalog.Monster(id)
	if err != nil {
		return content.MonsterDef{}, err
	}
	average, minimum := 25, 1
	if id == "MONS_QUOKKA" {
		average, minimum = 55, 3
	}
	if definition.AverageHP10x != average || !definition.LeavesCorpse {
		return content.MonsterDef{}, fmt.Errorf("unsupported ordinary animal definition %s", id)
	}
	if _, err := character.OrdinaryAnimalExperience(definition, minimum); err != nil {
		return content.MonsterDef{}, err
	}
	return definition, nil
}

func (g *Game) createScenarioAnimal(id string, levelID, x, y int) error {
	definition, err := g.ordinaryAnimal(id)
	if err != nil {
		return err
	}
	entity, err := g.world.CreateEntity()
	if err != nil {
		return err
	}
	if _, err := g.stores.Actors.Set(entity, ecs.Actor{KindID: id, Speed: definition.Speed}); err != nil {
		return err
	}
	hp, err := monster.RollHP(g.rng, definition.AverageHP10x)
	if err != nil {
		return err
	}
	if _, err := character.OrdinaryAnimalExperience(definition, hp); err != nil {
		return err
	}
	if _, err := g.stores.Health.Set(entity, ecs.Health{Current: hp, Max: hp}); err != nil {
		return err
	}
	if _, err := g.stores.Combat.Set(entity, ecs.Combatant{}); err != nil {
		return err
	}
	if _, err := g.stores.AI.Set(entity, ecs.MonsterAI{Behavior: "chase"}); err != nil {
		return err
	}
	return g.levels[levelID].PlaceActor(entity, x, y)
}
