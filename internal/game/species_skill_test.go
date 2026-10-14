package game

import (
	"testing"

	"dcrawl-go/internal/character"
)

func TestSelectedSpeciesAptitudeProjectsPlayerCombat(t *testing.T) {
	g := newStepGame(t)
	player, found := g.stores.Players.Get(g.player)

	if !found {
		t.Fatal("player has no selected species")
	}

	player.SpeciesID = "SP_TENGU"

	attack, err := newPlayerCombat(g).attackInput("MONS_RAT")

	if err != nil {
		t.Fatal(err)
	}

	if attack.WeaponSkill100 != 219 {
		t.Fatalf("Tengu Short Blades projection = %d, want 219",
			attack.WeaponSkill100)
	}

	delay, err := newPlayerCombat(g).attackDelayInput("MONS_RAT")

	if err != nil {
		t.Fatal(err)
	}

	if delay.WeaponSkill10 != 21 {
		t.Fatalf("Tengu attack-delay skill = %d, want 21",
			delay.WeaponSkill10)
	}

	if g.View().SpeciesID != "SP_TENGU" {
		t.Fatal("player view lost selected species")
	}
}

func TestSelectedSpeciesAptitudeSetsTrainedSkillLevel(t *testing.T) {
	g := newStepGame(t)
	player, _ := g.stores.Players.Get(g.player)

	player.SpeciesID = "SP_TENGU"

	if err := g.ChangeSkillTraining("SK_DODGING", false); err != nil {
		t.Fatal(err)
	}

	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)

	for index := range training.Settings {
		training.Settings[index].Enabled = training.Settings[index].ID == "SK_DODGING"
	}

	training.AvailableXP = 42

	if err := newSkillTrainingSystem(g).spend(skills, training); err != nil {
		t.Fatal(err)
	}

	for _, skill := range skills.Entries {
		if skill.ID == "SK_DODGING" {
			if skill.Points != 42 || skill.Level != 1 {
				t.Fatalf("Tengu Dodging = %+v, want 42 points at level 1", skill)
			}

			return
		}
	}

	t.Fatal("training did not create Dodging")
}

func TestSelectedSpeciesFightingTrainingRecalculatesBaseHP(t *testing.T) {
	g := newStepGame(t)
	player, _ := g.stores.Players.Get(g.player)

	player.SpeciesID = "SP_TENGU"

	training, _ := g.stores.SkillTraining.Get(g.player)

	for index := range training.Settings {
		training.Settings[index].Enabled = training.Settings[index].ID == "SK_FIGHTING"
	}

	training.AvailableXP = 42

	if err := newSkillTrainingSystem(g).Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(g.player)
	skills, _ := g.stores.Skills.Get(g.player)
	species, err := g.catalog.Species("SP_TENGU")

	if err != nil {
		t.Fatal(err)
	}

	want, err := character.BaseMaxHP(1, species, skills.Entries)

	if err != nil {
		t.Fatal(err)
	}

	if health.Max != want || training.SpentXP != 42 {
		t.Fatalf("Tengu Fighting changed HP to %d and spent %d XP; want %d and 42",
			health.Max, training.SpentXP, want)
	}
}

func TestSavedSkillLevelUsesSavedSpeciesAptitude(t *testing.T) {
	catalog := testCatalog(t)
	species, err := catalog.Species("SP_TENGU")

	if err != nil {
		t.Fatal(err)
	}

	entries := []character.Skill{
		{
			ID:     "SK_DODGING",
			Level:  1,
			Points: 42,
		},
	}

	known := map[string]bool{"SK_DODGING": true}

	if _, err := validateSavedSkillProgress(
		entries, nil, known, 42, species,
	); err != nil {
		t.Fatal(err)
	}

	entries[0].Level = 0

	if _, err := validateSavedSkillProgress(
		entries, nil, known, 42, species,
	); err == nil {
		t.Fatal("accepted a Human skill level for Tengu points")
	}
}
