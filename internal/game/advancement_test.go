package game

import (
	"strings"
	"testing"

	"dcrawl-go/internal/character"
)

func TestHumanAdvancementScalesVitalsAndWaitsForStatChoice(t *testing.T) {
	g := newStepGame(t)

	progress, _ := g.stores.Progression.Get(g.player)
	health, _ := g.stores.Health.Get(g.player)
	magic, _ := g.stores.Magic.Get(g.player)

	regeneration, _ := g.stores.Regeneration.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)

	health.Current = 9
	regeneration.HPProgress = 50
	oldMaxHP := health.Max
	startStrength := attributes.Strength

	progress.TotalXP = 9

	if err := g.advancement.Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	if progress.Level != 2 || progress.PendingStatLevel != 0 ||
		g.View().ExperienceLevel != 2 || g.View().NextLevelPercent != 0 {
		t.Fatalf("XL2 state = %+v, view %+v", progress, g.View())
	}

	wantHundred := (9*100 + 50) * health.Max / oldMaxHP

	if health.Current != wantHundred/100 ||
		regeneration.HPProgress != wantHundred%100 ||
		magic.Max != 2 || magic.Current != 2 {
		t.Fatalf("XL2 vitals: HP %+v MP %+v regeneration %+v", health, magic, regeneration)
	}

	progress.TotalXP = 29

	if err := g.advancement.Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	if progress.Level != 2 || progress.PendingStatLevel != 3 {
		t.Fatalf("manual stat choice did not hold XL3: %+v", progress)
	}

	beforeAut := g.currentAut
	blocked, err := g.Step(Command{Kind: CommandWait})

	if err != nil || blocked.Spent != 0 || g.currentAut != beforeAut {
		t.Fatalf("turn advanced during stat choice: %+v, %v", blocked, err)
	}

	invalid, err := g.ChooseStat("luck")

	if err != nil || invalid.Spent != 0 || progress.PendingStatLevel != 3 {
		t.Fatalf("invalid stat choice changed progression: %+v, %v", invalid, err)
	}

	chosen, err := g.ChooseStat("str")

	if err != nil {
		t.Fatal(err)
	}

	if chosen.Spent != 0 ||
		progress.Level != 3 ||
		progress.PendingStatLevel != 0 ||
		attributes.Strength != startStrength+2 || g.View().NextLevelPercent != 0 {
		t.Fatalf("XL3 stat choice = %+v, attrs %+v, view %+v", progress, attributes, g.View())
	}
}

func TestHumanAdvancementRunsThroughFinalLevel(t *testing.T) {
	g := newStepGame(t)
	progress, _ := g.stores.Progression.Get(g.player)
	attributes, _ := g.stores.Attributes.Get(g.player)
	baseStats := attributes.Strength + attributes.Intelligence + attributes.Dexterity

	lastThreshold, _ := character.HumanExperienceNeeded(character.HumanMaxLevel)
	progress.TotalXP = lastThreshold

	if err := g.advancement.Update(nil, 0); err != nil {
		t.Fatal(err)
	}

	for _, level := range []int{
		3,
		9,
		15,
		21,
		27,
	} {
		if progress.PendingStatLevel != level || progress.Level != level-1 {
			t.Fatalf("pending XL%d choice = %+v", level, progress)
		}

		if _, err := g.ChooseStat("dex"); err != nil {
			t.Fatal(err)
		}
	}

	if progress.Level != 27 || progress.PendingStatLevel != 0 ||
		g.View().ExperienceLevel != 27 || g.View().NextLevelPercent != 0 {
		t.Fatalf("final level state = %+v, view %+v", progress, g.View())
	}

	statTotal := attributes.Strength + attributes.Intelligence + attributes.Dexterity

	if statTotal != baseStats+5*2+6 {
		t.Fatalf("stat gains = %d, want %d", statTotal-baseStats, 16)
	}

	if _, err := g.ChooseStat("str"); err == nil {
		t.Fatal("accepted stat choice without a pending level")
	}

	seenFinalMessage := false

	for _, message := range g.View().Messages {
		seenFinalMessage = seenFinalMessage || strings.Contains(message, "final one")
	}

	if !seenFinalMessage {
		t.Fatal("final-level message missing")
	}
}

func TestStatChoiceInterruptsMonsterPhase(t *testing.T) {
	g := newStepGame(t)
	progress, _ := g.stores.Progression.Get(g.player)
	progress.Level = 2
	progress.TotalXP = 29

	monsterDeadlines := make(map[uint64]int64)

	for _, entity := range g.stores.AI.Entities() {
		actor, _ := g.stores.Actors.Get(entity)
		monsterDeadlines[uint64(entity)] = actor.NextAut
	}

	result, err := g.Step(Command{Kind: CommandWait})

	if err != nil {
		t.Fatal(err)
	}

	if result.View.PendingStatLevel != 3 || g.currentAut != 0 {
		t.Fatalf("stat prompt did not interrupt turn: %+v", result)
	}

	for _, entity := range g.stores.AI.Entities() {
		actor, _ := g.stores.Actors.Get(entity)

		if actor.NextAut != monsterDeadlines[uint64(entity)] {
			t.Fatalf("monster %d acted before stat choice", entity)
		}
	}

	chosen, err := g.ChooseStat("dex")

	if err != nil {
		t.Fatal(err)
	}

	if chosen.View.PendingStatLevel != 0 || chosen.View.ExperienceLevel != 3 ||
		g.currentAut != 10 {
		t.Fatalf("stat choice did not finish turn: %+v", chosen)
	}
}
