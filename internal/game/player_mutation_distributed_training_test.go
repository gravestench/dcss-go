package game

import (
	"testing"

	"dcrawl-go/internal/save"
)

func TestGnollDistributedTrainingStartsAndSpendsTogether(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_GNOLL",
		"JOB_FIGHTER",
		"WPN_WAR_AXE",
		"Gnoll",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	start := g.View()

	if len(start.Skills) != 28 ||
		len(start.SkillTraining.Settings) != 28 ||
		!start.SkillTraining.Manual {
		t.Fatalf("Gnoll did not start with all skills enabled: %+v", start.SkillTraining)
	}

	for _, setting := range start.SkillTraining.Settings {
		if !setting.Enabled || setting.Focused {
			t.Fatalf("Gnoll starts with adjustable training: %+v", setting)
		}
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	if len(restored.View().Skills) != 28 ||
		!restored.View().SkillTraining.Manual {
		t.Fatal("Gnoll's starting skills did not survive save and restore")
	}

	restored.Close()

	if err := g.ChangeSkillTraining("SK_AXES", false); err == nil {
		t.Fatal("Gnoll disabled a skill")
	}

	if err := g.SetSkillTrainingMode(false); err != nil {
		t.Fatal(err)
	}

	if !g.View().SkillTraining.Manual {
		t.Fatal("Gnoll entered automatic training")
	}

	before := make(map[string]int, len(start.Skills))

	for _, skill := range start.Skills {
		before[skill.ID] = skill.Points
	}

	training, _ := g.stores.SkillTraining.Get(g.player)

	training.AvailableXP = 30
	g.turn.Actor = g.player

	updateLuaSystem(t, g, "character.training", 10)

	trained := g.View()

	if trained.SkillTraining.AvailableXP != 2 ||
		trained.SkillTraining.SpentXP != 28 {
		t.Fatalf("Gnoll training spent the wrong XP: %+v", trained.SkillTraining)
	}

	for _, skill := range trained.Skills {
		if skill.Points != before[skill.ID]+1 {
			t.Errorf("%s gained %d points, want one", skill.ID,
				skill.Points-before[skill.ID])
		}
	}

}

func TestGnollTrainingRestoreRejectsChangedControls(t *testing.T) {
	g, err := NewDungeonGame(
		43,
		"SP_GNOLL",
		"JOB_FIGHTER",
		"WPN_WAR_AXE",
		"Gnoll",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()

	for _, tc := range []struct {
		name   string
		change func(*save.EntityRecord)
	}{
		{
			name: "automatic mode",
			change: func(record *save.EntityRecord) {
				record.SkillTraining.Manual = false
			},
		},

		{
			name: "disabled skill",
			change: func(record *save.EntityRecord) {
				record.SkillTraining.Settings[0].Enabled = false
			},
		},

		{
			name: "focused skill",
			change: func(record *save.EntityRecord) {
				record.SkillTraining.Settings[0].Focused = true
			},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			snapshot := g.Snapshot()

			for index := range snapshot.Entities {
				record := &snapshot.Entities[index]

				if record.ID == snapshot.PlayerID {
					tc.change(record)
					break
				}
			}

			if restored, err := Restore(snapshot); err == nil {
				restored.Close()
				t.Fatal("restored altered Gnoll training controls")
			}
		})
	}
}
