package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/monster"
	"github.com/gravestench/akara"
)

const legacyAnimalScenarioID = "fixed-dungeon-rat-quokka-v1"

const ordinaryMonsterScenarioID = "fixed-dungeon-rat-quokka-lizard-v2"

const populationScenarioID = "fixed-dungeon-population-v1"

const generatedDungeonScenarioID = "generated-dungeon-basic-v1"

const populationMonstersPerLevel = 2

var supportedFixedMonsters = []string{
	"MONS_RAT",
	"MONS_QUOKKA",
	"MONS_FRILLED_LIZARD",
}

var supportedPopulationMonsters = []string{
	"MONS_RAT",
	"MONS_QUOKKA",
	"MONS_FRILLED_LIZARD",
	"MONS_GIANT_COCKROACH",
	"MONS_WORM",
	"MONS_JACKAL",
	"MONS_ADDER",
}

func scenarioMonsterIDs(scenarioID string) ([]string, error) {
	switch scenarioID {
	case "":
		return []string{"MONS_RAT"}, nil

	case legacyAnimalScenarioID:
		return []string{"MONS_RAT", "MONS_QUOKKA"}, nil

	case ordinaryMonsterScenarioID:
		return append([]string(nil), supportedFixedMonsters...), nil

	case populationScenarioID:
		return append([]string(nil), supportedPopulationMonsters...), nil

	case generatedDungeonScenarioID:
		ids := append([]string(nil), supportedPopulationMonsters...)

		return append(ids,
			"MONS_BAT",
			"MONS_BALL_PYTHON",
			"MONS_ENDOPLASM",
			"MONS_DART_SLUG",
			"MONS_HOBGOBLIN",
		), nil

	default:
		return nil, fmt.Errorf("unsupported scenario ID %q", scenarioID)
	}
}

func isOrdinaryMonster(id string) bool {
	_, supported := character.OrdinaryNaturalProfileFor(id)

	return supported
}

func ordinaryMonster(catalog content.Catalog, id string) (content.MonsterDef, error) {
	profile, supported := character.OrdinaryNaturalProfileFor(id)

	if !supported {
		return content.MonsterDef{}, fmt.Errorf("unsupported ordinary monster %s", id)
	}

	definition, err := catalog.Monster(id)

	if err != nil {
		return content.MonsterDef{}, err
	}

	expectedCorpse := !profile.NoCorpse

	if definition.AverageHP10x != profile.AverageHP10x ||
		definition.LeavesCorpse != expectedCorpse {
		return content.MonsterDef{}, fmt.Errorf("unsupported ordinary monster definition %s", id)
	}

	if _, err := character.OrdinaryNaturalExperience(definition, profile.MinHP); err != nil {
		return content.MonsterDef{}, err
	}

	return definition, nil
}

// ordinaryMonsterFactory creates a live ECS actor from an immutable catalog
// definition. Scenario layout chooses the kind and position; the factory owns
// the HP draw and the complete component set.
type ordinaryMonsterFactory struct {
	world   *akara.World
	stores  ecs.Stores
	levels  map[int]*Level
	catalog content.Catalog
	rng     *RNGStreams
}

func newOrdinaryMonsterFactory(g *Game) ordinaryMonsterFactory {
	return ordinaryMonsterFactory{
		world:   g.world,
		stores:  g.stores,
		levels:  g.levels,
		catalog: g.catalog,
		rng:     g.rng,
	}
}

func (f ordinaryMonsterFactory) Spawn(
	id string,
	levelID, x, y int,
) (_ akara.Entity, err error) {
	definition, err := ordinaryMonster(f.catalog, id)

	if err != nil {
		return 0, err
	}

	level := f.levels[levelID]

	if level == nil || !level.Walkable(x, y) {
		return 0, fmt.Errorf("cannot place %s on level %d at (%d,%d)", id, levelID, x, y)
	}

	if _, occupied := level.ActorAt(x, y); occupied {
		return 0, fmt.Errorf("monster spawn tile (%d,%d) is occupied", x, y)
	}

	hp, err := monster.RollHP(f.rng, definition.AverageHP10x)

	if err != nil {
		return 0, err
	}

	if _, err := character.OrdinaryNaturalExperience(definition, hp); err != nil {
		return 0, err
	}

	entity, err := f.world.CreateEntity()

	if err != nil {
		return 0, err
	}

	defer func() {
		if err != nil {
			f.world.DestroyEntity(entity)
		}
	}()

	if _, err = f.stores.Actors.Set(entity, ecs.Actor{
		KindID: id,
		Speed:  definition.Speed,
	}); err != nil {
		return 0, err
	}

	if _, err = f.stores.MonsterEnergy.Set(entity, ecs.MonsterEnergy{
		Points: monster.InitialActionEnergy,
	}); err != nil {
		return 0, err
	}

	if _, err = f.stores.Health.Set(entity, ecs.Health{
		Current: hp,
		Max:     hp,
	}); err != nil {
		return 0, err
	}

	if _, err = f.stores.Combat.Set(entity, ecs.Combatant{}); err != nil {
		return 0, err
	}

	if _, err = f.stores.AI.Set(entity, ecs.MonsterAI{Behavior: "wander"}); err != nil {
		return 0, err
	}

	if err = level.PlaceActor(entity, x, y); err != nil {
		return 0, err
	}

	return entity, nil
}
