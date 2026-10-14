package monster

import (
	"fmt"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
)

const ActionEnergyThreshold = 80

const InitialActionEnergy = 70

// GainActionEnergy follows mon-act.cc:_monster_add_energy. Random rounding
// uses a saved stream and draws only when the division has a remainder.
func GainActionEnergy(roller Roller, speed, playerAut int) (int, error) {
	if roller == nil ||
		speed <= 0 ||
		playerAut <= 0 ||
		speed > int(^uint(0)>>1)/playerAut {
		return 0, fmt.Errorf("invalid monster speed %d over %d aut", speed, playerAut)
	}

	product := speed * playerAut
	gain := product / 10
	remainder := product % 10

	if remainder != 0 {
		roll, err := roller.Intn("monster_energy", 10)

		if err != nil {
			return 0, err
		}

		if roll < 0 || roll >= 10 {
			return 0, fmt.Errorf("monster energy draw %d outside [0,10)", roll)
		}

		if roll < remainder {
			gain++
		}
	}

	return max(1, gain), nil
}

// ActionEnergyCost reads the immutable mon-data.h energy table. The
// ordinary no-move path spends the cheaper land/swim movement cost.
func ActionEnergyCost(
	usage content.MonsterEnergy,
	intent ecs.IntentKind,
) (int, error) {
	cost := 0

	switch intent {
	case ecs.IntentMove:
		cost = usage.Move

	case ecs.IntentMelee:
		cost = usage.Attack

	case ecs.IntentSpell:
		cost = usage.Spell

	case ecs.IntentWait:
		cost = min(usage.Move, usage.Swim)

	default:
		return 0, fmt.Errorf("unsupported monster action %d", intent)
	}

	if cost <= 0 {
		return 0, fmt.Errorf("monster action %d has invalid energy cost %d", intent, cost)
	}

	return cost, nil
}
