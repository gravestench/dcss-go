package game

import (
	"dcrawl-go/internal/ecs"
	"fmt"
	"github.com/gravestench/akara"
	"strings"
	"testing"
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

func TestMinotaurHardHelmetCannotBeWornOrRestored(t *testing.T) {
	g := newMinotaurGame(t)
	helm := addCarriedArmour(t, g, "ARM_HELMET")

	blocked, err := g.Step(Command{
		Kind:   CommandWear,
		ItemID: uint64(helm),
	})

	if err != nil {
		t.Fatal(err)
	}

	if blocked.Spent != 0 {
		t.Fatal("hard helmet wear spent time despite horns")
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
		Remaining: 4,
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

	for level, needed := range []int{
		12,
		41,
		97,
	} {
		level += 2
		progress.TotalXP = needed

		if _, err := g.Step(Command{Kind: CommandWait}); err != nil {
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
