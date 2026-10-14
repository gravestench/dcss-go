package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/combat"
)

// playerAttackInput projects the live Fighter and committed rat catalog into
// one primary attack. It also checks equipment before a bump spends time.
func (g *Game) playerAttackInput() (combat.PlayerAttackInput, error) {
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
	rat, err := g.catalog.Monster("MONS_RAT")
	if err != nil {
		return combat.PlayerAttackInput{}, err
	}
	in := combat.PlayerAttackInput{Strength: attributes.Strength, Dexterity: attributes.Dexterity,
		DefenderEV: rat.EV, DefenderAC: rat.AC, Unarmed: player.StartingWeaponID == "WPN_UNARMED"}
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
