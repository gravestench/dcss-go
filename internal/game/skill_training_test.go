package game

import (
	"crawl/internal/character"
	"crawl/internal/ecs"
	"crawl/internal/save"
	"reflect"
	"testing"
)

func totalSkillPoints(skills []character.Skill) int {
	total := 0

	for _, skill := range skills {
		total += skill.Points
	}

	return total
}

func TestPlayerTrainingStateIsOwnedByAkaraAndSnapshotIsIsolated(t *testing.T) {
	g := newStepGame(t)
	training, found := g.stores.SkillTraining.Get(g.player)

	if !found {
		t.Fatal("player has no skill-training component")
	}

	if training.CostLevel != 1 ||
		training.AvailableXP != 0 ||
		training.SpentXP != 0 || len(training.Settings) != 4 {
		t.Fatalf("starting training state %+v", *training)
	}

	snapshot := g.Snapshot()
	var saved *ecs.SkillTraining

	for i := range snapshot.Entities {
		if snapshot.Entities[i].ID == snapshot.PlayerID {
			saved = snapshot.Entities[i].SkillTraining

			break
		}
	}

	if saved == nil {
		t.Fatal("player training is absent from snapshot")
	}

	saved.Settings[0].Enabled = false

	if !training.Settings[0].Enabled {
		t.Fatal("snapshot settings alias the live component")
	}

	saved.Settings[0].Enabled = true

	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	restoredTraining, found := restored.stores.SkillTraining.Get(restored.player)

	if !found || !restoredTraining.Settings[0].Enabled {
		t.Fatal("restored player lost skill training")
	}

	saved.Settings[0].Enabled = false

	if !restoredTraining.Settings[0].Enabled {
		t.Fatal("restored settings alias the save snapshot")
	}
}

func TestRestoreRejectsInvalidSkillTrainingState(t *testing.T) {
	g := newStepGame(t)

	tests := []struct {
		name   string
		mutate func(*save.EntityRecord)
	}{
		{
			name: "missing training component",
			mutate: func(record *save.EntityRecord) {
				record.SkillTraining = nil
			},
		},

		{
			name: "skill experience exceeds earned experience",
			mutate: func(record *save.EntityRecord) {
				record.SkillTraining.AvailableXP = 1
			},
		},

		{
			name: "wrong cost level",
			mutate: func(record *save.EntityRecord) {
				record.SkillTraining.CostLevel = 2
			},
		},

		{
			name: "skill level disagrees with points",
			mutate: func(record *save.EntityRecord) {
				record.Skills.Entries[0].Level = 26
			},
		},

		{
			name: "invalid Fighting level cannot reach HP projection",
			mutate: func(record *save.EntityRecord) {
				record.Skills.Entries[0].Level = 28
			},
		},

		{
			name: "unknown skill",
			mutate: func(record *save.EntityRecord) {
				record.Skills.Entries = append(record.Skills.Entries, character.Skill{
					ID: "SK_UNKNOWN",
				})

				record.SkillTraining.Settings = append(
					record.SkillTraining.Settings,
					ecs.SkillTrainingSetting{
						ID:      "SK_UNKNOWN",
						Enabled: true,
					},
				)
			},
		},

		{
			name: "practice queue is too long",
			mutate: func(record *save.EntityRecord) {
				record.SkillTraining.RecentPractice = make([]string, 101)
			},
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			bad := g.Snapshot()

			for i := range bad.Entities {
				if bad.Entities[i].ID == bad.PlayerID {
					test.mutate(&bad.Entities[i])

					break
				}
			}

			if restored, err := Restore(bad); err == nil {
				restored.Close()
				t.Fatal("restored invalid skill training state")
			}
		})
	}
}

func TestRatExperienceTrainsPlayerSkillsBeforeNextTurn(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	start, _ := g.stores.Skills.Get(g.player)
	startingPoints := totalSkillPoints(start.Entries)

	for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("rat survived 100 attacks")
	}

	training, _ := g.stores.SkillTraining.Get(g.player)
	progress, _ := g.stores.Progression.Get(g.player)

	if training.SpentXP == 0 ||
		training.AvailableXP+training.SpentXP != 10*progress.TotalXP ||
		totalSkillPoints(start.Entries) <= startingPoints {
		t.Fatalf("kill left training %+v and skills %+v", *training, start.Entries)
	}
}

func TestSkillTrainingChoicesDoNotSpendTime(t *testing.T) {
	g := newStepGame(t)
	beforeAut := g.currentAut

	if err := g.SetSkillTrainingMode(true); err != nil {
		t.Fatal(err)
	}

	if err := g.ChangeSkillTraining("SK_FIGHTING", false); err != nil {
		t.Fatal(err)
	}

	view := g.View()
	setting := view.SkillTraining.Settings[0]

	if !view.SkillTraining.Manual ||
		setting.Enabled ||
		view.SkillPercent[setting.ID] != 0 || g.currentAut != beforeAut {
		t.Fatalf("manual toggle changed time or wrong state: %+v", view.SkillTraining)
	}

	if err := g.ChangeSkillTraining("SK_DODGING", true); err != nil {
		t.Fatal(err)
	}

	view = g.View()
	last := view.SkillTraining.Settings[len(view.SkillTraining.Settings)-1]

	if last.ID != "SK_DODGING" ||
		!last.Enabled ||
		!last.Focused ||
		g.currentAut != beforeAut {
		t.Fatalf("focus choice changed time or wrong state: %+v", view.SkillTraining)
	}

	if err := g.ChangeSkillTraining("SK_UNKNOWN", false); err == nil {
		t.Fatal("accepted unknown training skill")
	}

	if err := g.ChangeSkillTraining("SK_SPELLCASTING", true); err != nil {
		t.Fatalf("could not train a catalog spell skill: %v", err)
	}

	if g.currentAut != beforeAut {
		t.Fatal("rejected skill choice spent game time")
	}
}

func TestSpellcastingTrainingRecalculatesMagic(t *testing.T) {
	g, err := NewDungeonGame(19, "SP_HUMAN", "JOB_FIRE_ELEMENTALIST", "", "Tester")

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	initialMagic, found := g.stores.Magic.Get(g.player)

	if !found {
		t.Fatal("caster has no magic component")
	}

	before := initialMagic.Max
	training, found := g.stores.SkillTraining.Get(g.player)

	if !found {
		t.Fatal("caster has no skill training")
	}

	training.Manual = true
	training.AvailableXP = 10000

	for index := range training.Settings {
		setting := &training.Settings[index]
		enabled := setting.ID == "SK_SPELLCASTING"

		setting.Enabled = enabled
		setting.Focused = setting.Enabled
	}

	g.turn.Actor = g.player
	updateLuaSystem(t, g, "character.training", 10)

	magic, found := g.stores.Magic.Get(g.player)

	if !found || magic.Max <= before {
		t.Fatalf("trained Spellcasting left MP at %+v, want more than %d", magic, before)
	}
}

func TestFirstAutoToggleDisablesUntrainedSkill(t *testing.T) {
	g := newStepGame(t)

	if err := g.ChangeSkillTraining("SK_DODGING", false); err != nil {
		t.Fatal(err)
	}

	view := g.View()
	setting := view.SkillTraining.Settings[len(view.SkillTraining.Settings)-1]

	if setting.ID != "SK_DODGING" || setting.Enabled {
		t.Fatalf("first automatic toggle should disable Dodging: %+v", setting)
	}
}

func TestDisabledTrainingKeepsExperienceUntilEnabled(t *testing.T) {
	g := newStepGame(t)
	rat := ratID(t, g)

	if err := g.SetSkillTrainingMode(true); err != nil {
		t.Fatal(err)
	}

	for _, setting := range g.View().SkillTraining.Settings {
		if err := g.ChangeSkillTraining(setting.ID, false); err != nil {
			t.Fatal(err)
		}
	}

	if err := g.levels[1].MoveActor(g.player, 3, 1); err != nil {
		t.Fatal(err)
	}

	health, _ := g.stores.Health.Get(rat)

	health.Current = 1

	for attempt := 0; attempt < 100 && g.world.EntityExists(rat); attempt++ {
		if _, err := g.Step(Command{
			Kind: CommandMove,
			DX:   1,
		}); err != nil {
			t.Fatal(err)
		}
	}

	if g.world.EntityExists(rat) {
		t.Fatal("rat survived 100 attacks")
	}

	training, _ := g.stores.SkillTraining.Get(g.player)

	if training.AvailableXP != 10 || training.SpentXP != 0 {
		t.Fatalf("disabled training spent XP: %+v", *training)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if err := restored.ChangeSkillTraining("SK_FIGHTING", false); err != nil {
		t.Fatal(err)
	}

	if _, err := restored.Step(Command{Kind: CommandWait}); err != nil {
		t.Fatal(err)
	}

	training, _ = restored.stores.SkillTraining.Get(restored.player)

	if training.SpentXP == 0 || training.AvailableXP+training.SpentXP != 10 {
		t.Fatalf("restored training did not spend retained XP: %+v", *training)
	}
}

func TestSkillRNGAndPracticeContinueAfterRestore(t *testing.T) {
	g := newStepGame(t)
	training, _ := g.stores.SkillTraining.Get(g.player)
	skills, _ := g.stores.Skills.Get(g.player)

	training.AvailableXP = 10
	training.Manual = true

	firstBefore := skills.Entries[0].Points
	secondBefore := skills.Entries[1].Points

	for index := range training.Settings {
		training.Settings[index].Enabled = index < 2
	}

	progress, _ := g.stores.Progression.Get(g.player)

	progress.TotalXP = 1

	// Remove a killed rat so the snapshot's earned XP remains possible.
	rat := ratID(t, g)

	if err := g.levels[1].RemoveActor(rat); err != nil {
		t.Fatal(err)
	}

	if !g.world.DestroyEntity(rat) {
		t.Fatal("could not remove killed rat")
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	for _, run := range []*Game{
		g,
		restored,
	} {
		if _, err := run.Step(Command{Kind: CommandWait}); err != nil {
			t.Fatal(err)
		}
	}

	if !reflect.DeepEqual(g.Snapshot(), restored.Snapshot()) {
		t.Fatal("skill practice or RNG diverged after restore")
	}

	if skills.Entries[0].Points != firstBefore+5 ||
		skills.Entries[1].Points != secondBefore+5 {
		t.Fatalf("restored batch allocation = %+v", skills.Entries)
	}
}
