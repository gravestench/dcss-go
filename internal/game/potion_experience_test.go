package game

import (
	"testing"

	"github.com/gravestench/akara"
)

func TestExperiencePotionRaisesLevelAndSavesSkillChoice(t *testing.T) {
	g := newStepGame(t)
	itemID := carryCuring(t, g)
	item, found := g.stores.Items.Get(akara.Entity(itemID))

	if !found {
		t.Fatal("carried potion missing")
	}

	item.KindID = "POT_EXPERIENCE"

	result, err := g.Step(Command{
		Kind:   CommandQuaff,
		ItemID: itemID,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 10 ||
		result.View.ExperienceLevel != 2 ||
		result.View.PendingSkillExperience != 7500 {
		t.Fatalf("experience potion view: level %d, pending %d, spent %d",
			result.View.ExperienceLevel,
			result.View.PendingSkillExperience,
			result.Spent)
	}

	loaded, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer loaded.Close()

	if loaded.View().PendingSkillExperience != 7500 {
		t.Fatal("pending potion skill experience was not saved")
	}

	if err := loaded.SpendPotionExperienceSkill("SK_FIGHTING"); err != nil {
		t.Fatal(err)
	}

	if loaded.View().PendingSkillExperience >= 7500 {
		t.Fatal("skill choice did not spend potion experience")
	}

	continued, err := Restore(loaded.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer continued.Close()

	if continued.View().PendingSkillExperience !=
		loaded.View().PendingSkillExperience {
		t.Fatal("allocated potion experience changed after restore")
	}
}
