package combat

import (
	"fmt"
	"math"
)

// Roller supplies bounded independent draws. Game owns its concrete RNG stream.
type Roller interface {
	Intn(string, int) (int, error)
}

// FighterDefense contains the live parts of an ordinary Human Fighter's defence.
type FighterDefense struct {
	Strength, Dexterity       int
	ArmourSkill, ShieldsSkill int
	BodyAC, BodyEV, BodyPlus  int
	ShieldAC, ShieldEV        int
	ShieldPlus, ShieldBlocks  int
}

// Defense is the source-derived value used to resolve one incoming attack.
type Defense struct {
	EV, AC, ShieldClass, GDR, ShieldBlocks int
}

// AnimalBite is a plain first bite from a supported ordinary animal.
type AnimalBite struct {
	HD, Damage        int
	TypeID, FlavourID string
}

type OutcomeKind uint8

const (
	Miss OutcomeKind = iota + 1
	Dodge
	Block
	Hit
)

type Outcome struct {
	Kind         OutcomeKind
	Damage       int
	ShieldBlocks int
}

// ProjectFighter follows the unmodified Human path in player.cc. Item EV is
// stored in hundredths in the committed catalog, as in item-prop.cc.
func ProjectFighter(in FighterDefense) (Defense, error) {
	if in.Strength <= 0 || in.Dexterity < 0 || in.ArmourSkill < 0 || in.ShieldsSkill < 0 ||
		in.BodyAC < 0 || in.BodyEV > 0 || in.ShieldAC < 0 || in.ShieldEV > 0 ||
		in.ShieldBlocks < 0 || in.BodyPlus < -100 || in.BodyPlus > 100 ||
		in.ShieldPlus < -100 || in.ShieldPlus > 100 {
		return Defense{}, fmt.Errorf("invalid Human Fighter defense %+v", in)
	}

	const scale = 100
	bodyEncumbrance := -in.BodyEV / 10
	bodyPenalty := 2 * bodyEncumbrance * bodyEncumbrance * (450 - in.ArmourSkill*10) * scale /
		(5 * (in.Strength + 3)) / 450
	if bodyPenalty < 0 {
		return Defense{}, fmt.Errorf("unsupported armour skill %d", in.ArmourSkill)
	}

	piecePenalty := (-in.BodyEV / 3) * scale / 10
	shieldPenalty := 0
	if in.ShieldAC > 0 {
		baseShieldPenalty := -in.ShieldEV / 10
		shieldPenalty = 2 * baseShieldPenalty * baseShieldPenalty *
			(270 - in.ShieldsSkill*10) * scale / (5 * 20) / 270
		if shieldPenalty < 0 {
			return Defense{}, fmt.Errorf("unsupported shields skill %d", in.ShieldsSkill)
		}
	}

	dodgeBonus := 800 * scale / 20 / 10 / 10 // zero Dodging at the supported start
	armourDodgePenalty := bodyEncumbrance - 3
	if armourDodgePenalty > 0 {
		if armourDodgePenalty >= in.Strength {
			dodgeBonus = dodgeBonus * in.Strength / (armourDodgePenalty * 2)
		} else {
			dodgeBonus -= dodgeBonus * armourDodgePenalty / (in.Strength * 2)
		}
	}

	naturalEV := 10*scale + dodgeBonus - piecePenalty - bodyPenalty - shieldPenalty
	if naturalEV < scale {
		naturalEV = scale
	}

	ev := (naturalEV + scale - 1) / scale

	baseAC := in.BodyAC * scale * (440 + in.ArmourSkill*20) / 440
	ac := (baseAC + in.BodyPlus*scale) / scale
	if ac < 0 {
		ac = 0
	}

	shieldClass := 0
	if in.ShieldAC > 0 {
		baseShield := in.ShieldAC * 2
		shield := baseShield*50 + baseShield*(in.ShieldsSkill*5)/2 +
			in.ShieldsSkill*38 + min(in.ShieldsSkill*38, 3*38) +
			in.Dexterity*38*(baseShield+13)/26 + in.ShieldPlus*200
		shieldClass = max(0, (shield+50)/100)
	}

	gdr := int(16 * math.Sqrt(math.Sqrt(float64(ac))))
	return Defense{
		EV:           ev,
		AC:           ac,
		ShieldClass:  shieldClass,
		GDR:          gdr,
		ShieldBlocks: in.ShieldBlocks,
	}, nil
}

func random2(r Roller, bound int) (int, error) {
	if bound <= 1 {
		return 0, nil
	}

	value, err := r.Intn("melee", bound)
	if err != nil {
		return 0, err
	}

	if value < 0 || value >= bound {
		return 0, fmt.Errorf("melee roll %d outside [0,%d)", value, bound)
	}

	return value, nil
}

func random2avg2(r Roller, bound int) (int, error) {
	first, err := random2(r, bound)
	if err != nil {
		return 0, err
	}

	second, err := random2(r, bound+1)
	if err != nil {
		return 0, err
	}

	return (first + second) / 2, nil
}

// ResolveAnimalBite follows the source's ordinary monster attack phase order.
func ResolveAnimalBite(r Roller, attack AnimalBite, defense Defense) (Outcome, error) {
	if r == nil || attack.TypeID != "AT_BITE" || attack.FlavourID != "AF_PLAIN" ||
		attack.HD <= 0 || attack.Damage <= 0 || defense.EV < 0 || defense.AC < 0 ||
		defense.ShieldClass < 0 || defense.GDR < 0 || defense.ShieldBlocks < 0 {
		return Outcome{}, fmt.Errorf("unsupported ordinary bite or defense: %+v %+v", attack, defense)
	}

	toHitBase := 18 + attack.HD*3/2 // supported animals have no M_FIGHTER flag
	toHit, err := random2(r, toHitBase+1)
	if err != nil {
		return Outcome{}, err
	}

	evRoll, err := random2avg2(r, 2*defense.EV)
	if err != nil {
		return Outcome{}, err
	}

	autoChance, err := random2(r, 100)
	if err != nil {
		return Outcome{}, err
	}

	autoMiss, autoHit := false, false
	if autoChance < 5 {
		coin, coinErr := random2(r, 2)
		if coinErr != nil {
			return Outcome{}, coinErr
		}

		autoMiss, autoHit = coin == 0, coin != 0
	}

	bypass := 15 + attack.HD*2/3 + 5*defense.ShieldBlocks*defense.ShieldBlocks
	conBlock, err := random2(r, bypass)
	if err != nil {
		return Outcome{}, err
	}

	proBlock := -100
	if defense.ShieldClass > 0 {
		shieldRoll, rollErr := random2avg2(r, defense.ShieldClass*2)
		if rollErr != nil {
			return Outcome{}, rollErr
		}

		proBlock = shieldRoll/3 - 1
	}

	if proBlock >= conBlock {
		return Outcome{
			Kind:         Block,
			ShieldBlocks: defense.ShieldBlocks + 1,
		}, nil
	}

	if autoMiss {
		return Outcome{
			Kind:         Miss,
			ShieldBlocks: defense.ShieldBlocks,
		}, nil
	}

	if !autoHit && toHit < evRoll {
		return Outcome{
			Kind:         Dodge,
			ShieldBlocks: defense.ShieldBlocks,
		}, nil
	}

	baseRoll, err := random2(r, attack.Damage)
	if err != nil {
		return Outcome{}, err
	}

	damage := 1 + baseRoll
	acRoll, err := random2(r, defense.AC+1)
	if err != nil {
		return Outcome{}, err
	}

	saved := acRoll
	// actor::apply_ac evaluates div_rand_round even if GDR later selects zero.
	maxGDR := defense.GDR * attack.Damage / 100
	acHalf := defense.AC / 2
	if defense.AC%2 != 0 {
		remainder, remainderErr := random2(r, 2)
		if remainderErr != nil {
			return Outcome{}, remainderErr
		}

		if remainder == 0 {
			acHalf++
		}
	}

	saved = max(saved, min(maxGDR, acHalf))
	return Outcome{
		Kind:         Hit,
		Damage:       max(0, damage-saved),
		ShieldBlocks: defense.ShieldBlocks,
	}, nil
}
