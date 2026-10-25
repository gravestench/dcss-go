package game

import (
	"strings"
	"testing"

	"github.com/gravestench/akara"
)

// Creation commits a complete future ancestry to ECS. Save/restore and the
// ordinary level-up path must use that plan without drawing a new one.
func TestDemonspawnScheduleSurvivesSaveAndGrantsXLTwo(t *testing.T) {
	g, err := NewDungeonGame(
		613,
		"SP_DEMONSPAWN",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Facet tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	traits := g.scripts.Components()["character.demonspawn_trait"]
	count := len(traits.Entities())

	if count != 15 && count != 18 {
		t.Fatalf("Demonspawn starts with %d scheduled grants", count)
	}

	first := firstDemonspawnTrait(t, g)
	level, err := first.Get("level")

	if err != nil {
		t.Fatal(err)
	}

	if level != int64(2) {
		t.Fatalf("first Demonspawn grant is XL%v", level)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if len(loaded.scripts.Components()["character.demonspawn_trait"].Entities()) != count {
		t.Fatal("restore changed the Demonspawn schedule")
	}

	progress, found := loaded.stores.Progression.Get(loaded.player)

	if !found {
		t.Fatal("restored Demonspawn has no progression")
	}

	progress.TotalXP = 1000

	training, found := loaded.stores.SkillTraining.Get(loaded.player)

	if !found {
		t.Fatal("restored Demonspawn has no skill training")
	}

	training.AvailableXP = 10 * progress.TotalXP

	if _, err := loaded.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	first = firstDemonspawnTrait(t, loaded)
	granted, err := first.Get("granted")

	if err != nil {
		t.Fatal(err)
	}

	if granted != true {
		t.Fatal("XL2 did not grant the first Demonspawn trait")
	}

	restored, err := Restore(loaded.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	first = firstDemonspawnTrait(t, restored)
	granted, err = first.Get("granted")

	if err != nil {
		t.Fatal(err)
	}

	if granted != true {
		t.Fatalf("restored XL2 trait = %v, %v", granted, err)
	}

	if err := first.Set("level", int64(1)); err != nil {
		t.Fatal(err)
	}

	invalid, err := Restore(restored.Snapshot())

	if invalid != nil {
		invalid.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "Demonspawn ancestry lacks XL2") {
		t.Fatalf("invalid Demonspawn level passed restore: %v", err)
	}
}

// Find the earliest saved grant through the same typed component store
// used by the Lua owner; entity iteration order has no gameplay meaning.
func firstDemonspawnTrait(t *testing.T, g *Game) *akara.DynamicComponent {
	t.Helper()
	store := g.scripts.Components()["character.demonspawn_trait"]
	var first *akara.DynamicComponent
	firstLevel := int64(28)

	for _, entity := range store.Entities() {
		record, found := store.Get(entity)

		if !found {
			t.Fatal("scheduled trait entity lost its component")
		}

		level, err := record.Get("level")

		if err != nil {
			t.Fatal(err)
		}

		if level.(int64) < firstLevel {
			first = record
			firstLevel = level.(int64)
		}
	}

	if first == nil {
		t.Fatal("Demonspawn has no scheduled traits")
	}

	return first
}
