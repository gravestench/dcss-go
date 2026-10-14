package combat

import "fmt"

// MonsterShot is the physical part of one launched or thrown attack. A
// launcher can supply a temporary projectile; a throw uses a carried one.
type MonsterShot struct {
	HD               int
	WeaponDamage     int
	WeaponHit        int
	WeaponPlus       int
	ProjectileDamage int
	NaturalDamage    int
}

// ResolveMonsterShot follows ranged-attack.cc and attack.cc for an ordinary
// physical missile. Brand effects run after this physical hit in game.
func ResolveMonsterShot(r Roller, shot MonsterShot, defense Defense) (Outcome, error) {
	if shot.WeaponDamage < 0 ||
		shot.ProjectileDamage < 0 ||
		shot.NaturalDamage < 0 ||
		shot.WeaponDamage+shot.ProjectileDamage <= 0 {
		return Outcome{}, fmt.Errorf("invalid monster shot %+v or defense %+v", shot, defense)
	}

	outcome, err := resolveMonsterRangedContact(
		r,
		shot.HD,
		shot.WeaponHit,
		shot.WeaponPlus,
		defense,
	)

	if err != nil {
		return Outcome{}, err
	}

	if outcome.Kind != Hit {
		return outcome, nil
	}

	// ranged_attack::weapon_damage adds projectile and launcher damage.
	// attack::calc_damage rolls that sum, then enchantment, then the fixed
	// one point from the monster's first attack definition.
	damageMax := shot.ProjectileDamage + shot.WeaponDamage
	damage, err := random2(r, damageMax)

	if err != nil {
		return Outcome{}, err
	}

	slayBound := 1 + shot.WeaponPlus

	if shot.WeaponPlus < 0 {
		slayBound = 1 - shot.WeaponPlus
	}

	slayRoll, err := random2(r, slayBound)

	if err != nil {
		return Outcome{}, err
	}

	if shot.WeaponPlus < 0 {
		damage -= slayRoll
	} else {
		damage += slayRoll
	}

	naturalRoll, err := random2(r, shot.NaturalDamage)

	if err != nil {
		return Outcome{}, err
	}

	damage += 1 + naturalRoll
	damageMax += shot.NaturalDamage

	acRoll, err := random2(r, defense.AC+1)

	if err != nil {
		return Outcome{}, err
	}

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

	saved := max(acRoll, min(defense.GDR*damageMax/100, acHalf))

	outcome.Damage = max(0, damage-saved)

	return outcome, nil
}

// ResolveMonsterPoisonDart uses dart_duration_roll rather than physical
// damage. The returned poison amount is applied only after a hit.
func ResolveMonsterPoisonDart(
	r Roller,
	hitDice int,
	defense Defense,
) (Outcome, int, error) {
	outcome, err := resolveMonsterRangedContact(r, hitDice, 0, 0, defense)

	if err != nil {
		return Outcome{}, 0, err
	}

	if outcome.Kind != Hit {
		return outcome, 0, nil
	}

	durationRoll, err := random2(r, 8)

	if err != nil {
		return Outcome{}, 0, err
	}

	return outcome, 6 + durationRoll, nil
}

// resolveMonsterRangedContact preserves the source's shared to-hit, shield,
// and evasion draw order for launcher shots, stones, and darts.
func resolveMonsterRangedContact(
	r Roller,
	hitDice, weaponHit, weaponPlus int,
	defense Defense,
) (Outcome, error) {
	if r == nil ||
		hitDice <= 0 ||
		weaponPlus < -32768 ||
		weaponPlus > 32767 ||
		defense.EV < 0 ||
		defense.AC < 0 ||
		defense.GDR < 0 ||
		defense.ShieldClass < 0 ||
		defense.ShieldBlocks < 0 {
		return Outcome{}, fmt.Errorf("invalid ranged contact HD %d or defense %+v", hitDice, defense)
	}

	// These first draws mirror attack::calc_to_hit and test_hit. The latter
	// rolls EV and the 5 percent automatic hit/miss before shield resolution.
	baseHit := 18 + hitDice*3/2 + weaponHit + weaponPlus

	if baseHit < 0 {
		baseHit = 0
	}

	toHit, err := random2(r, baseHit+1)

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

	// attack_shield_blocked runs even when the projectile misses EV.
	bypass := 15 + hitDice*2/3 +
		5*defense.ShieldBlocks*defense.ShieldBlocks
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

	if autoMiss || (!autoHit && toHit < evRoll) {
		return Outcome{
			Kind:         Dodge,
			ShieldBlocks: defense.ShieldBlocks,
		}, nil
	}

	return Outcome{
		Kind:         Hit,
		ShieldBlocks: defense.ShieldBlocks,
	}, nil
}
