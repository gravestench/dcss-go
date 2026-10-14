package game

import (
	"reflect"
	"testing"
	"time"

	"dcrawl-go/internal/character"
	"dcrawl-go/internal/combat"
	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/save"
)

func TestPlayerTrainingStateIsOwnedByAkaraAndSnapshotIsIsolated(t *testing.T) {
	g := newStepGame(t)
	training, found := g.stores.SkillTraining.Get(g.player)

	if !found {
		t.Fatal("player has no skill-training component")
	}

	if training.CostLevel != 1 || training.AvailableXP != 0 ||
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
	restored, err := Restore(snapshot, testCatalog(t))

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
			name: "unsupported magic skill",
			mutate: func(record *save.EntityRecord) {
				record.Skills.Entries = append(record.Skills.Entries, character.Skill{
					ID: "SK_SPELLCASTING",
				})

				record.SkillTraining.Settings = append(
					record.SkillTraining.Settings,
					ecs.SkillTrainingSetting{
						ID:      "SK_SPELLCASTING",
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

			if restored, err := Restore(bad, testCatalog(t)); err == nil {
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

	if !view.SkillTraining.Manual || setting.Enabled ||
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

	if err := g.ChangeSkillTraining("SK_SPELLCASTING", true); err == nil {
		t.Fatal("accepted training for an unavailable spell skill")
	}

	if g.currentAut != beforeAut {
		t.Fatal("rejected skill choice spent game time")
	}
}

func TestRareFocusedAutomaticSkillReceivesSourceWeight(t *testing.T) {
	skills := []character.Skill{
		{ID: "SK_FIGHTING"},
		{ID: "SK_DODGING"},
	}

	training := &ecs.SkillTraining{
		Settings: []ecs.SkillTrainingSetting{
			{
				ID:      "SK_FIGHTING",
				Enabled: true,
				Focused: true,
			},
			{
				ID:      "SK_DODGING",
				Enabled: true,
			},
		},
		RecentPractice: []string{"SK_FIGHTING"},
	}

	for i := 0; i < 99; i++ {
		training.RecentPractice = append(training.RecentPractice, "SK_DODGING")
	}

	weights := trainingWeights(skills, training)

	if weights[0] != 27 || weights[1] != 99 {
		t.Fatalf("source focus weights = %v, want [27 99]", weights)
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

func TestFightingPracticeRecalculatesHPBeforeAdvancement(t *testing.T) {
	g := newStepGame(t)
	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)
	health, _ := g.stores.Health.Get(g.player)

	skills.Entries[0].Points = 433
	training.SpentXP = 132
	training.AvailableXP = 2

	training.CostLevel = 2
	training.Manual = true

	for i := 1; i < len(training.Settings); i++ {
		training.Settings[i].Enabled = false
	}

	species, err := g.catalog.Species("SP_HUMAN")

	if err != nil {
		t.Fatal(err)
	}

	health.Max, err = character.HumanMaxHP(1, species, skills.Entries)

	if err != nil {
		t.Fatal(err)
	}

	health.Current = health.Max
	before := health.Max
	system := newSkillTrainingSystem(g)

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	want, err := character.HumanMaxHP(1, species, skills.Entries)

	if err != nil {
		t.Fatal(err)
	}

	if want <= before || health.Max != want || health.Current != want {
		t.Fatalf("Fighting points %d left HP %+v, want %d", skills.Entries[0].Points, *health, want)
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

	restored, err := Restore(g.Snapshot(), testCatalog(t))

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

func TestMaxedSkillsLeaveSkillExperienceUnspent(t *testing.T) {
	g := newStepGame(t)
	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)
	maximum, err := character.HumanSkillPointsNeeded(character.HumanMaxSkillLevel)

	if err != nil {
		t.Fatal(err)
	}

	for i := range skills.Entries {
		skills.Entries[i].Level = character.HumanMaxSkillLevel
		skills.Entries[i].Points = maximum
	}

	training.AvailableXP = 100
	system := newSkillTrainingSystem(g)

	if err := system.Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if training.AvailableXP != 100 || training.SpentXP != 0 {
		t.Fatalf("maxed skills consumed XP: %+v", *training)
	}
}

func TestTrainingChangesCostAtSpentExperienceBoundary(t *testing.T) {
	g := newStepGame(t)
	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)

	skills.Entries[0].Points = 417

	training.AvailableXP = 3
	training.SpentXP = 116
	training.Manual = true

	for i := 1; i < len(training.Settings); i++ {
		training.Settings[i].Enabled = false
	}

	if err := newSkillTrainingSystem(g).Update(nil, time.Duration(10)); err != nil {
		t.Fatal(err)
	}

	if skills.Entries[0].Points != 419 ||
		training.SpentXP != 119 ||
		training.AvailableXP != 0 ||
		training.CostLevel != 2 {
		t.Fatalf("training crossed cost boundary incorrectly: %+v, %+v", skills.Entries[0], *training)
	}
}

func TestSkillRNGAndPracticeContinueAfterRestore(t *testing.T) {
	g := newStepGame(t)
	training, _ := g.stores.SkillTraining.Get(g.player)
	training.AvailableXP = 10

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

	restored, err := Restore(g.Snapshot(), testCatalog(t))

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
}

func TestPracticeCreatesZeroPointHumanSkillAndKeepsBoundedQueues(t *testing.T) {
	g := newStepGame(t)
	skills, _ := g.stores.Skills.Get(g.player)
	training, _ := g.stores.SkillTraining.Get(g.player)
	system := newSkillTrainingSystem(g)

	for i := 0; i < 101; i++ {
		if err := system.recordPractice(skills, training, "SK_DODGING"); err != nil {
			t.Fatal(err)
		}
	}

	if len(skills.Entries) != 5 ||
		skills.Entries[4].ID != "SK_DODGING" ||
		skills.Entries[4].Points != 0 ||
		len(training.RecentPractice) != 100 ||
		len(training.RecentAll) != 100 ||
		training.RecentPractice[99] != "SK_DODGING" {
		t.Fatalf("new practice state: skills %+v, training %+v", skills.Entries, *training)
	}

	if err := system.recordPractice(skills, training, "SK_UNKNOWN"); err == nil {
		t.Fatal("accepted practice for unknown skill")
	}
}

func TestSupportedCombatEventsProduceSkillPractice(t *testing.T) {
	g := newStepGame(t)
	system := newCombatSystem(g)
	attack := combat.PlayerAttackInput{
		Unarmed:       true,
		WeaponSkillID: "SK_UNARMED_COMBAT",
	}

	if err := system.practicePlayerHit(attack, "MONS_RAT"); err != nil {
		t.Fatal(err)
	}

	if len(g.turn.Practice) != 1 || g.turn.Practice[0] != "SK_UNARMED_COMBAT" {
		t.Fatalf("unarmed hit practice %+v", g.turn.Practice)
	}

	for i := 0; i < 100; i++ {
		if err := system.practiceAnimalAttack(
			combat.Outcome{Kind: combat.Hit},
			combat.Defense{
				BodyEV:      -100,
				ShieldClass: 9,
			},
		); err != nil {
			t.Fatal(err)
		}
	}

	for _, id := range []string{
		"SK_DODGING",
		"SK_SHIELDS",
		"SK_ARMOUR",
		"SK_FIGHTING",
	} {
		if !containsPractice(g.turn.Practice, id) {
			t.Fatalf("combat practice lacks %s: %+v", id, g.turn.Practice)
		}
	}
}

func containsPractice(practice []string, id string) bool {
	for _, candidate := range practice {
		if candidate == id {
			return true
		}
	}

	return false
}

func totalSkillPoints(skills []character.Skill) int {
	total := 0

	for _, skill := range skills {
		total += skill.Points
	}

	return total
}
