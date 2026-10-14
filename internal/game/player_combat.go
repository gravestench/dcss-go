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
	player akara.Entity

	players    *akara.Store[ecs.PlayerControlled]
	attributes *akara.Store[ecs.Attributes]
	skills     *akara.Store[ecs.Skills]
	durations  *akara.Store[ecs.Durations]
	combat     *akara.Store[ecs.Combatant]

	equipped *akara.Store[ecs.Equipped]
	carried  *akara.Store[ecs.CarriedBy]
	items    *akara.Store[ecs.Item]

	catalog content.Catalog
}

func newPlayerCombat(g *Game) playerCombat {
	s := g.stores

	return playerCombat{
		player: g.player,

		players:    s.Players,
		attributes: s.Attributes,
		skills:     s.Skills,
		durations:  s.Durations,
		combat:     s.Combat,

		equipped: s.Equipped,
		carried:  s.CarriedBy,
		items:    s.Items,

		catalog: g.catalog,
	}
}

func (c playerCombat) selectedSpecies() (content.SpeciesDef, error) {
	player, found := c.players.Get(c.player)

	if !found {
		return content.SpeciesDef{}, fmt.Errorf("player has no character choice")
	}

	return c.catalog.Species(player.SpeciesID)
}

func scaledSpeciesSkill(
	skill character.Skill,
	scale int,
	species content.SpeciesDef,
) (int, error) {
	aptitude, err := species.SkillAptitude(skill.ID)

	if err != nil {
		return 0, err
	}

	return character.ScaledSkill(skill, scale, aptitude)
}

// attackInput projects the live Fighter against a cataloged defender.
// It also checks equipment before a bump spends time.
func (c playerCombat) attackInput(defenderID string) (combat.PlayerAttackInput, error) {
	species, err := c.selectedSpecies()

	if err != nil {
		return combat.PlayerAttackInput{}, err
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

	if err := projectAttackSkills(&in, *skills, species); err != nil {
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

		if !carried ||
			carrier.Holder != c.player || equipment.Slot != "weapon" {
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

func projectAttackSkills(
	in *combat.PlayerAttackInput,
	skills ecs.Skills,
	species content.SpeciesDef,
) error {
	fightingFound := false

	for _, skill := range skills.Entries {
		if skill.ID == "SK_FIGHTING" {
			scaled, err := scaledSpeciesSkill(skill, 100, species)

			if err != nil {
				return err
			}

			in.FightingSkill100 = scaled
			fightingFound = true

			continue
		}

		if skill.ID != in.WeaponSkillID {
			continue
		}

		scaled, err := scaledSpeciesSkill(skill, 100, species)

		if err != nil {
			return err
		}

		in.WeaponSkill100 = scaled

		if in.Unarmed {
			scaled, err := scaledSpeciesSkill(skill, 256, species)

			if err != nil {
				return err
			}

			in.UnarmedSkill256 = scaled
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

	species, err := c.selectedSpecies()

	if err != nil {
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
			scaled, err := scaledSpeciesSkill(skill, 10, species)

			if err != nil {
				return combat.AttackDelayInput{}, err
			}

			in.WeaponSkill10 = scaled
		}

		if skill.ID == "SK_SHIELDS" {
			scaled, err := scaledSpeciesSkill(skill, 10, species)

			if err != nil {
				return combat.AttackDelayInput{}, err
			}

			in.ShieldsSkill10 = scaled
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
			if shieldFound ||
				kind.Armour == nil || kind.Slot != "shield" {
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
	species, err := c.selectedSpecies()

	if err != nil {
		return combat.Defense{}, err
	}

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

		case "SK_DODGING":
			scaled, err := scaledSpeciesSkill(skill, 10, species)

			if err != nil {
				return combat.Defense{}, err
			}

			input.DodgingSkill10 = scaled
		}
	}

	for _, entity := range c.equipped.Entities() {
		carrier, carried := c.carried.Get(entity)

		if !carried || carrier.Holder != c.player {
			continue
		}

		equipped, _ := c.equipped.Get(entity)

		if !supportedArmourSlot(equipped.Slot) {
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

		piece := combat.ArmourPiece{
			AC:   kind.Armour.AC,
			EV:   kind.Armour.EV,
			Plus: item.Plus,
		}

		switch equipped.Slot {
		case "body":
			input.Body = piece

		case "shield":
			input.Shield = piece

		case "head", "cloak", "gloves", "boots":
			input.Auxiliary = append(input.Auxiliary, piece)
		}
	}

	return combat.ProjectFighter(input)
}

func (c playerCombat) skillLevel(id string) int {
	skills, found := c.skills.Get(c.player)

	if !found {
		return 0
	}

	for _, skill := range skills.Entries {
		if skill.ID == id {
			return skill.Level
		}
	}

	return 0
}
