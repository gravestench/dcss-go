package combat

import (
	"fmt"
	"math"
)

// Roller supplies bounded independent draws. Game owns its concrete RNG stream.
type Roller interface {
	Intn(string, int) (int, error)
}

// ArmourPiece is one worn item's base AC, EV penalty, and enchantment.
type ArmourPiece struct {
	AC   int
	EV   int
	Plus int
}

// FighterDefense contains the live parts of a supported Fighter's defence.
type FighterDefense struct {
	Strength       int
	Dexterity      int
	ArmourSkill    int
	ShieldsSkill   int
	DodgingSkill10 int

	Body      ArmourPiece
	Shield    ArmourPiece
	Auxiliary []ArmourPiece

	ShieldBlocks int
}

// Defense is the source-derived value used to resolve one incoming attack.
type Defense struct {
	EV           int
	AC           int
	ShieldClass  int
	GDR          int
	ShieldBlocks int
	BodyEV       int
}

// MeleeWeapon is the live weapon contribution to one monster hit.
type MeleeWeapon struct {
	Damage int
	Hit    int
	Plus   int
}

// NaturalAttack is the first attack of a supported ordinary monster.
// An AT_HIT monster can add its equipped melee weapon to the natural hit.
type NaturalAttack struct {
	HD        int
	Damage    int
	TypeID    string
	FlavourID string
	Weapon    *MeleeWeapon
}

// PoisonBiteAmount follows melee-attack.cc's 1-in-3 normal poison flavour.
// A zero result means the flavour did not trigger after the bite landed.
func PoisonBiteAmount(r Roller, hitDice int) (int, error) {
	if r == nil ||
		hitDice <= 0 || hitDice > 1000 {
		return 0, fmt.Errorf("invalid poison bite hit dice %d", hitDice)
	}

	trigger, err := random2(r, 3)

	if err != nil {
		return 0, err
	}

	if trigger != 0 {
		return 0, nil
	}

	roll, err := random2(r, 2*hitDice+1)

	if err != nil {
		return 0, err
	}

	return 2*hitDice + roll, nil
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

// ProjectFighter follows the ordinary player path in player.cc. Item EV is
// stored in hundredths in the committed catalog, as in item-prop.cc.
func ProjectFighter(in FighterDefense) (Defense, error) {
	invalidStats := in.Strength <= 0 ||
		in.Dexterity < 0 ||
		in.ArmourSkill < 0 ||
		in.ShieldsSkill < 0 ||
		in.DodgingSkill10 < 0
	invalidArmour := invalidArmourPiece(in.Body)
	invalidShield := invalidArmourPiece(in.Shield) || in.ShieldBlocks < 0

	for _, piece := range in.Auxiliary {
		invalidArmour = invalidArmour || invalidArmourPiece(piece)
	}

	if invalidStats ||
		invalidArmour || invalidShield {
		return Defense{}, fmt.Errorf("invalid Fighter defense %+v", in)
	}

	const scale = 100
	bodyEncumbrance := -in.Body.EV / 10
	bodyPenalty := 2 * bodyEncumbrance * bodyEncumbrance * (450 - in.ArmourSkill*10) * scale /
		(5 * (in.Strength + 3)) / 450

	if bodyPenalty < 0 {
		return Defense{}, fmt.Errorf("unsupported armour skill %d", in.ArmourSkill)
	}

	// player.cc sums each non-shield base EV penalty before scaling.
	piecePenalty := -in.Body.EV / 3

	for _, piece := range in.Auxiliary {
		piecePenalty += -piece.EV / 3
	}

	piecePenalty = piecePenalty * scale / 10
	shieldPenalty := 0

	if in.Shield.AC > 0 {
		baseShieldPenalty := -in.Shield.EV / 10
		shieldPenalty = 2 * baseShieldPenalty * baseShieldPenalty *
			(270 - in.ShieldsSkill*10) * scale / (5 * 20) / 270

		if shieldPenalty < 0 {
			return Defense{}, fmt.Errorf("unsupported shields skill %d", in.ShieldsSkill)
		}
	}

	dodgeBonus := (800 + in.DodgingSkill10*in.Dexterity*8) *
		scale / 20 / 10 / 10
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

	armourSkillFactor := 440 + in.ArmourSkill*20
	baseAC := in.Body.AC * scale * armourSkillFactor / 440
	baseAC += in.Body.Plus * scale

	// player.cc sums scaled AC from every non-shield item before rounding.
	for _, piece := range in.Auxiliary {
		baseAC += piece.AC * scale * armourSkillFactor / 440
		baseAC += piece.Plus * scale
	}

	ac := baseAC / scale

	if ac < 0 {
		ac = 0
	}

	shieldClass := 0

	if in.Shield.AC > 0 {
		baseShield := in.Shield.AC * 2
		shield := baseShield*50 + baseShield*(in.ShieldsSkill*5)/2 +
			in.ShieldsSkill*38 + min(in.ShieldsSkill*38, 3*38) +
			in.Dexterity*38*(baseShield+13)/26 + in.Shield.Plus*200
		shieldClass = max(0, (shield+50)/100)
	}

	gdr := int(16 * math.Sqrt(math.Sqrt(float64(ac))))

	return Defense{
		EV:           ev,
		AC:           ac,
		ShieldClass:  shieldClass,
		GDR:          gdr,
		ShieldBlocks: in.ShieldBlocks,
		BodyEV:       in.Body.EV,
	}, nil
}

func invalidArmourPiece(piece ArmourPiece) bool {
	return piece.AC < 0 ||
		piece.EV > 0 ||
		piece.Plus < -100 ||
		piece.Plus > 100
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

// ResolveNaturalAttack follows the source's ordinary monster attack phase order.
func ResolveNaturalAttack(r Roller, attack NaturalAttack, defense Defense) (Outcome, error) {
	ordinaryAttack := (attack.TypeID == "AT_BITE" || attack.TypeID == "AT_HIT") &&
		(attack.FlavourID == "AF_PLAIN" || attack.FlavourID == "AF_POISON")
	constrictGrab := attack.TypeID == "AT_CONSTRICT" &&
		attack.FlavourID == "AF_CRUSH"
	invalidWeapon := attack.Weapon != nil &&
		(attack.TypeID != "AT_HIT" ||
			attack.Weapon.Damage <= 0 ||
			attack.Weapon.Plus < -32768 ||
			attack.Weapon.Plus > 32767)

	if r == nil ||
		(!ordinaryAttack && !constrictGrab) ||
		invalidWeapon ||
		attack.HD <= 0 ||
		attack.Damage <= 0 ||
		defense.EV < 0 ||
		defense.AC < 0 ||
		defense.ShieldClass < 0 ||
		defense.GDR < 0 || defense.ShieldBlocks < 0 {
		return Outcome{}, fmt.Errorf("unsupported natural attack or defense: %+v %+v", attack, defense)
	}

	toHitBase := 18 + attack.HD*3/2 // supported monsters have no M_FIGHTER flag

	if attack.Weapon != nil {
		toHitBase += attack.Weapon.Hit + attack.Weapon.Plus
	}

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

	if constrictGrab {
		// AF_CRUSH attaches a grip; damage is resolved after the action.
		return Outcome{
			Kind:         Hit,
			ShieldBlocks: defense.ShieldBlocks,
		}, nil
	}

	weaponDamage := 0
	potentialDamage := attack.Damage

	if attack.Weapon != nil {
		weaponDamage, err = random2(r, attack.Weapon.Damage)

		if err != nil {
			return Outcome{}, err
		}

		// attack.cc:_core_apply_slaying rolls the enchantment before the
		// natural attack damage, including a zero-effect roll for +0.
		slayBound := 1 + attack.Weapon.Plus

		if attack.Weapon.Plus < 0 {
			slayBound = 1 - attack.Weapon.Plus
		}

		slayRoll, rollErr := random2(r, slayBound)

		if rollErr != nil {
			return Outcome{}, rollErr
		}

		if attack.Weapon.Plus < 0 {
			weaponDamage -= slayRoll
		} else {
			weaponDamage += slayRoll
		}

		potentialDamage += attack.Weapon.Damage
	}

	baseRoll, err := random2(r, attack.Damage)

	if err != nil {
		return Outcome{}, err
	}

	damage := weaponDamage + 1 + baseRoll
	acRoll, err := random2(r, defense.AC+1)

	if err != nil {
		return Outcome{}, err
	}

	saved := acRoll
	// actor::apply_ac evaluates div_rand_round even if GDR later selects zero.
	maxGDR := defense.GDR * potentialDamage / 100
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
