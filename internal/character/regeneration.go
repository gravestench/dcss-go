package character

import "fmt"

// Vitality is a supported Fighter's live HP/MP and fractional recovery.
// Each progress counter holds hundredths of one point between player actions.
type Vitality struct {
	HP         int
	MaxHP      int
	MP         int
	MaxMP      int
	HPProgress int
	MPProgress int
}

// Regenerate applies player_reacts' HP and MP recovery for one player action.
// Other species, equipment, mutations, and magical modifiers enter later.
func Regenerate(roller Roller, state Vitality, actionAut int) (Vitality, error) {
	invalidHP := state.MaxHP <= 0 ||
		state.HP <= 0 ||
		state.HP > state.MaxHP
	invalidMP := state.MaxMP < 0 ||
		state.MP < 0 ||
		state.MP > state.MaxMP
	invalidProgress := state.HPProgress < 0 ||
		state.HPProgress >= 100 ||
		state.MPProgress < 0 ||
		state.MPProgress >= 100

	if roller == nil ||
		actionAut < 0 ||
		invalidHP ||
		invalidMP ||
		invalidProgress {
		return Vitality{}, fmt.Errorf("invalid regeneration state %+v or aut %d", state, actionAut)
	}

	hpRate := state.MaxHP / 3

	if hpRate > 20 {
		hpRate = 20 + (hpRate-20)/2
	}

	hpRate = max(1, hpRate)
	hpGain, err := regenerationCount(roller, hpRate, actionAut)

	if err != nil {
		return Vitality{}, err
	}

	state.HPProgress += hpGain

	for state.HPProgress >= 100 {
		state.HP = min(state.MaxHP, state.HP+1)
		state.HPProgress -= 100
	}

	if state.MP < state.MaxMP {
		mpRate := 7 + state.MaxMP/2
		mpGain, err := regenerationCount(roller, mpRate, actionAut)

		if err != nil {
			return Vitality{}, err
		}

		state.MPProgress += mpGain
	}

	for state.MPProgress >= 100 {
		state.MP = min(state.MaxMP, state.MP+1)
		state.MPProgress -= 100
	}

	return state, nil
}

func regenerationCount(roller Roller, rate, actionAut int) (int, error) {
	numerator := rate * actionAut
	count, remainder := numerator/10, numerator%10

	if remainder == 0 {
		return count, nil
	}

	roll, err := roller.Intn("regeneration", 10)

	if err != nil {
		return 0, err
	}

	if roll < 0 || roll >= 10 {
		return 0, fmt.Errorf("regeneration roll %d outside [0,10)", roll)
	}

	if roll < remainder {
		count++
	}

	return count, nil
}
