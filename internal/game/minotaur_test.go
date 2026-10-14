package game

import (
	"fmt"
	"reflect"
	"strings"
	"testing"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/ecs"
	"github.com/gravestench/akara"
)

type zeroMeleeRoller struct{}

func (zeroMeleeRoller) Intn(stream string, bound int) (int, error) {
	if stream != "melee" || bound < 1 {
		return 0, errUnexpectedMeleeRoll(stream, bound)
	}

	return 0, nil
}

func errUnexpectedMeleeRoll(stream string, bound int) error {
	return fmt.Errorf("unexpected %s roll bound %d", stream, bound)
}

func newMinotaurGame(t *testing.T) *Game {
	t.Helper()
	g, err := NewDungeonGame(
		1,
		testCatalog(t),
		"SP_MINOTAUR",
		"JOB_FIGHTER",
		"WPN_FLAIL",
		"Aster",
	)

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		g.Close()
	})

	return g
}

func firstMinotaurTarget(t *testing.T, g *Game) akara.Entity {
	t.Helper()

	for _, entity := range g.stores.AI.Entities() {
		position, found := g.stores.Positions.Get(entity)

		if found && position.LevelID == 1 {
			return entity
		}
	}

	t.Fatal("generated D:1 has no target")

	return 0
}

func TestMinotaurAuxiliaryRunsAfterPrimaryMiss(t *testing.T) {
	g := newMinotaurGame(t)
	target := firstMinotaurTarget(t, g)

	// A direct system call isolates combat order from monster scheduling.
	g.turn.Actor = g.player

	system := newCombatSystem(g)

	system.roller = zeroMeleeRoller{}

	victim, _ := g.stores.Health.Get(target)

	if err := system.resolvePlayerMelee(target, victim); err != nil {
		t.Fatal(err)
	}

	if len(g.turn.Events) != 2 ||
		!strings.Contains(g.turn.Events[0].Text, "You miss") ||
		!strings.Contains(g.turn.Events[1].Text, "headbutt") {
		t.Fatalf("primary miss and auxiliary events = %+v", g.turn.Events)
	}
}

func TestMinotaurReflexiveMissAndSaveRestore(t *testing.T) {
	g := newMinotaurGame(t)
	target := firstMinotaurTarget(t, g)

	g.turn.Actor = target

	system := newCombatSystem(g)

	system.roller = zeroMeleeRoller{}

	playerHealth, _ := g.stores.Health.Get(g.player)

	before := playerHealth.Current

	if err := system.resolveAnimalMelee(playerHealth); err != nil {
		t.Fatal(err)
	}

	if playerHealth.Current != before ||
		len(g.turn.Events) < 3 ||
		!strings.Contains(g.turn.Events[len(g.turn.Events)-2].Text, "furiously retaliate") {
		t.Fatalf("reflexive events = %+v, HP %d", g.turn.Events, playerHealth.Current)
	}

	loaded, err := Restore(g.Snapshot(), testCatalog(t))

	if err != nil {
		t.Fatal(err)
	}

	t.Cleanup(func() {
		loaded.Close()
	})

	if !reflect.DeepEqual(g.Snapshot(), loaded.Snapshot()) {
		t.Fatal("Minotaur combat snapshot changed on restore")
	}

	actor, _ := loaded.stores.Actors.Get(target)
	in, err := newPlayerCombat(loaded).headbuttInput(actor.KindID)

	if err != nil {
		t.Fatal(err)
	}

	if in.Horns != 2 || !in.Reflexive {
		t.Fatalf("restored innate headbutt = %+v, %v", in, err)
	}
}

func TestMinotaurHeadbuttKillAwardsPlayerExperience(t *testing.T) {
	g := newMinotaurGame(t)
	target := firstMinotaurTarget(t, g)
	actor, _ := g.stores.Actors.Get(target)
	victim, _ := g.stores.Health.Get(target)

	victim.Current = 1
	g.turn.Actor = g.player

	in, err := newPlayerCombat(g).headbuttInput(actor.KindID)

	if err != nil {
		t.Fatal(err)
	}

	toHit := (1300 + in.Dexterity*75 + in.FightingSkill30) / 100
	potential := (5 + in.Horns*3) * max(2, 150+5*in.Strength) / 2 / 100
	rolls := []combatRoll{
		{
			bound: 100,
			value: 0,
		},

		{
			bound: toHit,
			value: 0,
		},

		{
			bound: 30,
			value: 0,
		},

		{
			bound: 15,
			value: 0,
		},

		{
			bound: potential,
			value: potential - 1,
		},

		{
			bound: in.FightingSkill100 + 1,
			value: 0,
		},

		{
			bound: in.DefenderAC + 1,
			value: 0,
		},
	}

	if in.DefenderAC%2 != 0 {
		rolls = append(rolls, combatRoll{
			bound: 2,
			value: 0,
		})
	}

	roller := &combatRoller{rolls: rolls}
	system := newCombatSystem(g)

	system.roller = roller

	definition, _ := g.catalog.Monster(actor.KindID)

	if err := system.resolveAuxiliaryHeadbutt(
		target,
		victim,
		definition.Name,
		actor.KindID,
	); err != nil {
		t.Fatal(err)
	}

	if victim.Current != 0 ||
		g.turn.PlayerKill != target ||
		len(roller.rolls) != 0 {
		t.Fatalf("headbutt kill: HP %d, killer %d, rolls %+v",
			victim.Current, g.turn.PlayerKill, roller.rolls)
	}

	if err := newDeathSystem(g).Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)

	if progress.TotalXP <= 0 {
		t.Fatal("headbutt kill did not award player experience")
	}
}

func TestMinotaurReflexiveKillAwardsPlayerExperience(t *testing.T) {
	g := newMinotaurGame(t)
	target := firstMinotaurTarget(t, g)
	actor, _ := g.stores.Actors.Get(target)
	victim, _ := g.stores.Health.Get(target)

	victim.Current = 1
	g.turn.Actor = target

	in, err := newPlayerCombat(g).headbuttInput(actor.KindID)

	if err != nil {
		t.Fatal(err)
	}

	potential := (5 + in.Horns*3) * max(2, 150+5*in.Strength) / 2 / 100
	rolls := []combatRoll{
		{
			bound: 100,
			value: 0,
		},

		{
			bound: potential,
			value: potential - 1,
		},

		{
			bound: in.FightingSkill100 + 1,
			value: 0,
		},

		{
			bound: in.DefenderAC + 1,
			value: 0,
		},
	}

	if in.DefenderAC%2 != 0 {
		rolls = append(rolls, combatRoll{
			bound: 2,
			value: 0,
		})
	}

	roller := &combatRoller{rolls: rolls}
	system := newCombatSystem(g)

	system.roller = roller

	definition, _ := g.catalog.Monster(actor.KindID)

	if err := system.resolveReflexiveHeadbutt(
		definition.Name,
		actor.KindID,
	); err != nil {
		t.Fatal(err)
	}

	if victim.Current != 0 ||
		g.turn.PlayerKill != target ||
		len(roller.rolls) != 0 {
		t.Fatalf("reflexive kill: HP %d, killer %d, rolls %+v",
			victim.Current, g.turn.PlayerKill, roller.rolls)
	}

	if err := newDeathSystem(g).Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	progress, _ := g.stores.Progression.Get(g.player)

	if progress.TotalXP <= 0 {
		t.Fatal("reflexive kill did not award player experience")
	}
}

func TestMinotaurHardHelmetCannotBeWornOrRestored(t *testing.T) {
	g := newMinotaurGame(t)
	helm := addCarriedArmour(t, g, "ARM_HELMET")

	addCarriedArmour(t, g, "ARM_HAT")
	helmKind, _ := g.catalog.Item("ARM_HELMET")
	hatKind, _ := g.catalog.Item("ARM_HAT")

	if err := g.validateWearFit(helmKind); err == nil {
		t.Fatal("hard helmet fits horns")
	}

	if err := g.validateWearFit(hatKind); err != nil {
		t.Fatalf("soft hat does not fit: %v", err)
	}

	if _, err := g.stores.Equipped.Set(helm, ecs.Equipped{
		Slot: "head",
	}); err != nil {
		t.Fatal(err)
	}

	if restored, err := Restore(g.Snapshot(), testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("restored equipped hard helmet on horns")
	} else if !strings.Contains(err.Error(), "horns") {
		t.Fatalf("equipped helmet rejected for another reason: %v", err)
	}

	g.stores.Equipped.Remove(helm)

	if _, err := g.stores.Equipment.Set(g.player, ecs.EquipmentDelay{
		ItemID:    helm,
		Slot:      "head",
		Phase:     "wear",
		Remaining: armourEquipTurns - 1,
	}); err != nil {
		t.Fatal(err)
	}

	if restored, err := Restore(g.Snapshot(), testCatalog(t)); err == nil {
		restored.Close()
		t.Fatal("restored pending hard helmet wear")
	} else if !strings.Contains(err.Error(), "horns") {
		t.Fatalf("pending helmet rejected for another reason: %v", err)
	}

}

func TestMinotaurFighterGainsStrengthOrDexterityAtFourthLevel(t *testing.T) {
	g := newMinotaurGame(t)
	progress, _ := g.stores.Progression.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)
	species, _ := g.catalog.Species("SP_MINOTAUR")

	for level := 2; level <= 4; level++ {
		needed, err := character.ExperienceNeeded(level, species.XP)

		if err != nil {
			t.Fatal(err)
		}

		progress.TotalXP = needed

		if err := g.advancement.advance(); err != nil {
			t.Fatal(err)
		}

		if level == 3 {
			if _, err := g.ChooseStat("int"); err != nil {
				t.Fatal(err)
			}
		}
	}

	if progress.Level != 4 ||
		attributes.Intelligence != 7 ||
		attributes.Strength+attributes.Dexterity != 30 {
		t.Fatalf("Minotaur XL4 = %+v, %+v", progress, attributes)
	}
}
