package game

import (
	"strings"
	"testing"
)

func addSkillSacrificeForTest(t *testing.T, g *Game, mutationID string) {
	t.Helper()

	entity, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	_, err = g.scripts.Components()["character.mutation"].Set(
		entity,
		map[string]any{
			"owner":       g.player,
			"mutation_id": mutationID,
			"acquired":    int64(1),
		},
	)

	if err != nil {
		t.Fatal(err)
	}
}

func TestAirSchoolSacrificeRejectsKnownSpellWithoutTime(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_AIR_ELEMENTALIST",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	addSkillSacrificeForTest(t, g, "MUT_NO_AIR_MAGIC")

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:    CommandCast,
		SpellID: "SPELL_SHOCK",
		DX:      1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatalf("forbidden school spent %d aut", result.Spent)
	}

	if len(result.Events) == 0 ||
		!strings.Contains(result.Events[0].Text,
			"cannot use spells of this school") {
		t.Fatalf("missing school refusal: %+v", result.Events)
	}
}

func TestHexesSacrificeRejectsMemorisation(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_HEDGE_WIZARD",
		"",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	addSkillSacrificeForTest(t, g, "MUT_NO_HEXES_MAGIC")

	result, err := g.scripts.Policy("magic.begin_learning",
		map[string]any{
			"spell_id": "SPELL_SLOW",
		})

	if err != nil {
		t.Fatal(err)
	}

	if result["started"] == true ||
		result["message"] != "You cannot memorise that spell." {
		t.Fatalf("forbidden school memorisation = %+v", result)
	}
}

func TestDodgingSacrificeCannotBeReenabled(t *testing.T) {
	g := newStepGame(t)
	addSkillSacrificeForTest(t, g, "MUT_NO_DODGING")

	before := g.currentAut
	err := g.ChangeSkillTraining("SK_DODGING", true)

	if err == nil {
		t.Fatal("forbidden skill training change was accepted")
	}

	if !strings.Contains(err.Error(), "cannot train that skill") {
		t.Fatalf("forbidden training change = %v", err)
	}

	if g.currentAut != before {
		t.Fatal("forbidden training change spent time")
	}
}

func TestSacrificedStartingSkillSurvivesSaveRestore(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_HUMAN",
		"JOB_GLADIATOR",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	addSkillSacrificeForTest(t, g, "MUT_NO_DODGING")

	skills, found := g.stores.Skills.Get(g.player)

	if !found {
		t.Fatal("player has no skills")
	}

	training, found := g.stores.SkillTraining.Get(g.player)

	if !found {
		t.Fatal("player has no skill training")
	}

	cleared := false

	for index := range skills.Entries {
		if skills.Entries[index].ID == "SK_DODGING" {
			skills.Entries[index].Level = 0
			skills.Entries[index].Points = 0
			cleared = true
		}
	}

	for index := range training.Settings {
		if training.Settings[index].ID == "SK_DODGING" {
			training.Settings[index].Enabled = false
			training.Settings[index].Focused = false
		}
	}

	if !cleared {
		t.Fatal("Gladiator lacks a starting Dodging skill")
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	for _, skill := range loaded.View().Skills {
		if skill.ID == "SK_DODGING" &&
			(skill.Level != 0 || skill.Points != 0) {
			t.Fatalf("restored Dodging skill = %+v", skill)
		}
	}
}
