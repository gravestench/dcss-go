package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/combat"
)

// playerAttackInput projects the live Fighter against a cataloged defender.
// It also checks equipment before a bump spends time.
func (g *Game) playerAttackInput(defenderID string) (combat.PlayerAttackInput, error) {
	player, found := g.stores.Players.Get(g.player)
	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no character choice")
	}
	attributes, found := g.stores.Attributes.Get(g.player)
	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no attributes")
	}
	skills, found := g.stores.Skills.Get(g.player)
	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no skills")
	}
	defender, err := g.catalog.Monster(defenderID)
	if err != nil {
		return combat.PlayerAttackInput{}, err
	}
	in := combat.PlayerAttackInput{Strength: attributes.Strength, Dexterity: attributes.Dexterity,
		DefenderEV: defender.EV, DefenderAC: defender.AC, Unarmed: player.StartingWeaponID == "WPN_UNARMED"}
	if durations, found := g.stores.Durations.Get(g.player); found {
		in.Mighty = durations.MightAut > 0
	}
	if in.Unarmed {
		in.WeaponSkillID = "SK_UNARMED_COMBAT"
	}
	weaponCount := 0
	for _, entity := range g.stores.Equipped.Entities() {
		equipment, _ := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)
		if !carried || carrier.Holder != g.player || equipment.Slot != "weapon" {
			continue
		}
		weaponCount++
		item, found := g.stores.Items.Get(entity)
		if !found || in.Unarmed || item.KindID != player.StartingWeaponID {
			return combat.PlayerAttackInput{}, fmt.Errorf("equipped weapon does not match starting weapon %s", player.StartingWeaponID)
		}
		kind, err := g.catalog.Item(item.KindID)
		if err != nil {
			return combat.PlayerAttackInput{}, err
		}
		if err := validateItemProperties(*item, kind); err != nil {
			return combat.PlayerAttackInput{}, fmt.Errorf("equipped weapon %d has %w", entity, err)
		}
		if kind.Weapon == nil || kind.Weapon.SkillID != kind.WeaponSkill {
			return combat.PlayerAttackInput{}, fmt.Errorf("weapon %s has no supported melee properties", kind.ID)
		}
		in.WeaponSkillID = kind.Weapon.SkillID
		in.WeaponDamage, in.WeaponHit, in.WeaponPlus = kind.Weapon.Damage, kind.Weapon.Hit, item.Plus
	}
	if (in.Unarmed && weaponCount != 0) || (!in.Unarmed && weaponCount != 1) {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has %d equipped weapons for %s", weaponCount, player.StartingWeaponID)
	}
	fightingFound, weaponSkillFound := false, false
	for _, skill := range skills.Entries {
		switch skill.ID {
		case "SK_FIGHTING":
			in.FightingSkill100 = character.ScaledSkill(skill, 100)
			fightingFound = true
		default:
			if skill.ID == in.WeaponSkillID {
				in.WeaponSkill100 = character.ScaledSkill(skill, 100)
				if in.Unarmed {
					in.UnarmedSkill256 = character.ScaledSkill(skill, 256)
				}
				weaponSkillFound = true
			}
		}
	}
	if !fightingFound || !weaponSkillFound {
		return combat.PlayerAttackInput{}, fmt.Errorf("player attack lacks Fighting or %s skill", in.WeaponSkillID)
	}
	if err := in.Validate(); err != nil {
		return combat.PlayerAttackInput{}, err
	}
	return in, nil
}

// playerAttackDelayInput reads the same live weapon and stored skill points
// used by accuracy and damage, plus the currently equipped shield.
func (g *Game) playerAttackDelayInput(defenderID string) (combat.AttackDelayInput, error) {
	attack, err := g.playerAttackInput(defenderID)
	if err != nil {
		return combat.AttackDelayInput{}, err
	}
	if _, err := g.fighterDefense(); err != nil {
		return combat.AttackDelayInput{}, err
	}
	in := combat.AttackDelayInput{Unarmed: attack.Unarmed, WeaponSkillID: attack.WeaponSkillID}
	skills, _ := g.stores.Skills.Get(g.player)
	weaponSkillFound, shieldSkillFound := false, false
	for _, skill := range skills.Entries {
		if skill.ID == in.WeaponSkillID {
			in.WeaponSkill10 = character.ScaledSkill(skill, 10)
			weaponSkillFound = true
		}
		if skill.ID == "SK_SHIELDS" {
			in.ShieldsSkill10 = character.ScaledSkill(skill, 10)
			shieldSkillFound = true
		}
	}
	if !weaponSkillFound || !shieldSkillFound {
		return combat.AttackDelayInput{}, fmt.Errorf("player attack timing lacks weapon or Shields skill")
	}
	shieldFound := false
	for _, entity := range g.stores.Equipped.Entities() {
		equipped, _ := g.stores.Equipped.Get(entity)
		carrier, carried := g.stores.CarriedBy.Get(entity)
		if !carried || carrier.Holder != g.player {
			continue
		}
		if equipped.Slot != "weapon" && equipped.Slot != "shield" {
			continue
		}
		item, found := g.stores.Items.Get(entity)
		if !found {
			return combat.AttackDelayInput{}, fmt.Errorf("equipped item %d is missing", entity)
		}
		kind, err := g.catalog.Item(item.KindID)
		if err != nil {
			return combat.AttackDelayInput{}, err
		}
		if equipped.Slot == "weapon" {
			if kind.Weapon == nil || in.Unarmed {
				return combat.AttackDelayInput{}, fmt.Errorf("unsupported equipped attack weapon %s", kind.ID)
			}
			in.WeaponSpeed = kind.Weapon.Speed
		} else {
			if shieldFound || kind.Armour == nil || kind.Slot != "shield" {
				return combat.AttackDelayInput{}, fmt.Errorf("unsupported equipped shield %s", kind.ID)
			}
			if err := validateItemProperties(*item, kind); err != nil {
				return combat.AttackDelayInput{}, fmt.Errorf("equipped shield %d has %w", entity, err)
			}
			in.ShieldEV = kind.Armour.EV
			shieldFound = true
		}
	}
	if !shieldFound {
		return combat.AttackDelayInput{}, fmt.Errorf("player attack timing lacks equipped shield")
	}
	if err := in.Validate(); err != nil {
		return combat.AttackDelayInput{}, err
	}
	return in, nil
}
