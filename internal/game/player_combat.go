package game

import (
	"fmt"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

// playerCombat projects the live Fighter's ECS state into combat rules.
// It owns no copy of mutable character state; every method reads its stores.
type playerCombat struct {
	player     akara.Entity
	players    *akara.Store[ecs.PlayerControlled]
	attributes *akara.Store[ecs.Attributes]
	skills     *akara.Store[ecs.Skills]
	durations  *akara.Store[ecs.Durations]
	combat     *akara.Store[ecs.Combatant]
	equipped   *akara.Store[ecs.Equipped]
	carried    *akara.Store[ecs.CarriedBy]
	items      *akara.Store[ecs.Item]
	catalog    content.Catalog
}

func newPlayerCombat(g *Game) playerCombat {
	s := g.stores

	return playerCombat{
		player:     g.player,
		players:    s.Players,
		attributes: s.Attributes,
		skills:     s.Skills,
		durations:  s.Durations,
		combat:     s.Combat,
		equipped:   s.Equipped,
		carried:    s.CarriedBy,
		items:      s.Items,
		catalog:    g.catalog,
	}
}

// attackInput projects the live Fighter against a cataloged defender.
// It also checks equipment before a bump spends time.
func (c playerCombat) attackInput(defenderID string) (combat.PlayerAttackInput, error) {
	_, found := c.players.Get(c.player)

	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no character choice")
	}

	attributes, found := c.attributes.Get(c.player)

	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no attributes")
	}

	skills, found := c.skills.Get(c.player)

	if !found {
		return combat.PlayerAttackInput{}, fmt.Errorf("player has no skills")
	}

	defender, err := c.catalog.Monster(defenderID)

	if err != nil {
		return combat.PlayerAttackInput{}, err
	}

	in := combat.PlayerAttackInput{
		Strength:   attributes.Strength,
		Dexterity:  attributes.Dexterity,
		DefenderEV: defender.EV,
		DefenderAC: defender.AC,
	}

	if durations, found := c.durations.Get(c.player); found {
		in.Mighty = durations.MightAut > 0
	}

	if err := c.projectAttackWeapon(&in); err != nil {
		return combat.PlayerAttackInput{}, err
	}

	if err := projectAttackSkills(&in, *skills); err != nil {
		return combat.PlayerAttackInput{}, err
	}

	if err := in.Validate(); err != nil {
		return combat.PlayerAttackInput{}, err
	}

	return in, nil
}

func (c playerCombat) projectAttackWeapon(in *combat.PlayerAttackInput) error {
	weaponCount := 0

	for _, entity := range c.equipped.Entities() {
		equipment, _ := c.equipped.Get(entity)
		carrier, carried := c.carried.Get(entity)

		if !carried || carrier.Holder != c.player || equipment.Slot != "weapon" {
			continue
		}

		weaponCount++
		item, found := c.items.Get(entity)

		if !found {
			return fmt.Errorf("equipped weapon %d has no item", entity)
		}

		kind, err := c.catalog.Item(item.KindID)

		if err != nil {
			return err
		}

		if err := validateItemProperties(*item, kind); err != nil {
			return fmt.Errorf("equipped weapon %d has %w", entity, err)
		}

		if kind.Weapon == nil || kind.Weapon.SkillID != kind.WeaponSkill {
			return fmt.Errorf(
				"weapon %s has no supported melee properties",
				kind.ID,
			)
		}

		in.WeaponSkillID = kind.Weapon.SkillID
		in.WeaponDamage = kind.Weapon.Damage
		in.WeaponHit = kind.Weapon.Hit
		in.WeaponPlus = item.Plus
	}

	if weaponCount > 1 {
		return fmt.Errorf("player has %d equipped weapons", weaponCount)
	}

	if weaponCount == 0 {
		in.Unarmed = true
		in.WeaponSkillID = "SK_UNARMED_COMBAT"
	}

	return nil
}

func projectAttackSkills(in *combat.PlayerAttackInput, skills ecs.Skills) error {
	fightingFound := false

	for _, skill := range skills.Entries {
		if skill.ID == "SK_FIGHTING" {
			in.FightingSkill100 = character.ScaledSkill(skill, 100)
			fightingFound = true

			continue
		}

		if skill.ID != in.WeaponSkillID {
			continue
		}

		in.WeaponSkill100 = character.ScaledSkill(skill, 100)

		if in.Unarmed {
			in.UnarmedSkill256 = character.ScaledSkill(skill, 256)
		}
	}

	// An untrained newly wielded weapon has zero skill points, as in DCSS.
	if !fightingFound {
		return fmt.Errorf("player attack lacks Fighting skill")
	}

	return nil
}

// attackDelayInput reads the same live weapon and stored skill points
// used by accuracy and damage, plus the currently equipped shield.
func (c playerCombat) attackDelayInput(defenderID string) (combat.AttackDelayInput, error) {
	attack, err := c.attackInput(defenderID)

	if err != nil {
		return combat.AttackDelayInput{}, err
	}

	if _, err := c.defense(); err != nil {
		return combat.AttackDelayInput{}, err
	}

	in := combat.AttackDelayInput{
		Unarmed:       attack.Unarmed,
		WeaponSkillID: attack.WeaponSkillID,
	}

	skills, _ := c.skills.Get(c.player)
	shieldSkillFound := false

	for _, skill := range skills.Entries {
		if skill.ID == in.WeaponSkillID {
			in.WeaponSkill10 = character.ScaledSkill(skill, 10)
		}

		if skill.ID == "SK_SHIELDS" {
			in.ShieldsSkill10 = character.ScaledSkill(skill, 10)
			shieldSkillFound = true
		}
	}

	if !shieldSkillFound {
		return combat.AttackDelayInput{}, fmt.Errorf("player attack timing lacks Shields skill")
	}

	shieldFound := false

	for _, entity := range c.equipped.Entities() {
		equipped, _ := c.equipped.Get(entity)
		carrier, carried := c.carried.Get(entity)

		if !carried || carrier.Holder != c.player {
			continue
		}

		if equipped.Slot != "weapon" && equipped.Slot != "shield" {
			continue
		}

		item, found := c.items.Get(entity)

		if !found {
			return combat.AttackDelayInput{}, fmt.Errorf("equipped item %d is missing", entity)
		}

		kind, err := c.catalog.Item(item.KindID)

		if err != nil {
			return combat.AttackDelayInput{}, err
		}

		if equipped.Slot == "weapon" {
			if kind.Weapon == nil || in.Unarmed {
				return combat.AttackDelayInput{}, fmt.Errorf(
					"unsupported equipped attack weapon %s",
					kind.ID,
				)
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

	if err := in.Validate(); err != nil {
		return combat.AttackDelayInput{}, err
	}

	return in, nil
}

func (c playerCombat) defense() (combat.Defense, error) {
	attributes, found := c.attributes.Get(c.player)

	if !found {
		return combat.Defense{}, fmt.Errorf("player has no attributes")
	}

	skills, found := c.skills.Get(c.player)

	if !found {
		return combat.Defense{}, fmt.Errorf("player has no skills")
	}

	state, found := c.combat.Get(c.player)

	if !found {
		return combat.Defense{}, fmt.Errorf("player has no combat state")
	}

	input := combat.FighterDefense{
		Strength:     attributes.Strength,
		Dexterity:    attributes.Dexterity,
		ShieldBlocks: state.ShieldBlocks,
	}

	for _, skill := range skills.Entries {
		switch skill.ID {
		case "SK_ARMOUR":
			input.ArmourSkill = skill.Level

		case "SK_SHIELDS":
			input.ShieldsSkill = skill.Level
		}
	}

	for _, entity := range c.equipped.Entities() {
		carrier, carried := c.carried.Get(entity)

		if !carried || carrier.Holder != c.player {
			continue
		}

		equipped, _ := c.equipped.Get(entity)

		if equipped.Slot != "body" && equipped.Slot != "shield" {
			continue
		}

		item, found := c.items.Get(entity)

		if !found {
			return combat.Defense{}, fmt.Errorf("equipped entity %d has no item", entity)
		}

		kind, err := c.catalog.Item(item.KindID)

		if err != nil {
			return combat.Defense{}, err
		}

		if kind.Armour == nil {
			return combat.Defense{}, fmt.Errorf("equipped %s has no armour properties", kind.ID)
		}

		if equipped.Slot == "body" {
			input.BodyAC = kind.Armour.AC
			input.BodyEV = kind.Armour.EV
			input.BodyPlus = item.Plus
		} else {
			input.ShieldAC = kind.Armour.AC
			input.ShieldEV = kind.Armour.EV
			input.ShieldPlus = item.Plus
		}
	}

	return combat.ProjectFighter(input)
}
