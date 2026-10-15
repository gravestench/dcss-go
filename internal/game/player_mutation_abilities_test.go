package game

import (
	"strings"
	"testing"
)

func TestMutationAbilityCommandUsesLuaPreparation(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_HOP",
		DX:        1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 {
		t.Fatalf("unowned Hop spent %d aut", result.Spent)
	}

	addPlayerMutation(t, g, "MUT_HOP")
	before, _ := g.stores.Positions.Get(g.player)
	startX := before.X
	startY := before.Y

	result, err = g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_HOP",
		DX:        1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("owned Hop did not spend an action")
	}

	after, _ := g.stores.Positions.Get(g.player)

	if after.X == startX && after.Y == startY {
		t.Fatal("Hop ability did not move the player")
	}

	if !g.scripts.Components()["character.ability_cooldowns"].Has(g.player) {
		t.Fatal("Hop did not start its cooldown")
	}
}

func TestHurlDamnationUsesAbilityCostsAndLuaExplosion(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	addPlayerMutation(t, g, "MUT_HURL_DAMNATION")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	health, _ := g.stores.Health.Get(g.player)

	health.Max = 100
	health.Current = 100

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_DAMNATION",
		DX:        4,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Hurl Damnation did not spend an action")
	}

	if health.Max-health.Current < 15 {
		t.Fatalf("Hurl Damnation left %d missing HP, want at least 15",
			health.Max-health.Current)
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "sphere of damnation explodes") {
			return
		}
	}

	t.Fatalf("Hurl Damnation had no Lua explosion: %+v", result.Events)
}

func TestWordOfChaosUsesLuaAbilityAndCooldown(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	addPlayerMutation(t, g, "MUT_WORD_OF_CHAOS")
	progress, _ := g.stores.Progression.Get(g.player)

	progress.Level = 27

	magic, _ := g.stores.Magic.Get(g.player)

	magic.Max = 30
	magic.Current = 30

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_WORD_OF_CHAOS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Word of Chaos did not spend an action")
	}

	for _, event := range result.Events {
		if strings.Contains(event.Text, "speak a word of chaos") {
			if !g.scripts.Components()["character.ability_cooldowns"].Has(g.player) {
				t.Fatal("Word of Chaos did not start its cooldown")
			}

			return
		}
	}

	t.Fatalf("Word of Chaos had no Lua effect event: %+v", result.Events)
}

func TestRestoreRejectsNegativeMutationAbilityCooldown(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	_, err := g.scripts.Components()["character.ability_cooldowns"].Set(
		g.player,
		map[string]any{
			"hop_aut":           int64(-1),
			"word_of_chaos_aut": int64(0),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	loaded, err := Restore(g.Snapshot())

	if loaded != nil {
		loaded.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "ability cooldown") {
		t.Fatalf("negative ability cooldown was accepted: %v", err)
	}
}

func TestPoisonBreathCooldownSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_SPIT_POISON")

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_SPIT_POISON",
		DX:        1,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("Spit Poison did not spend an action")
	}

	before, found := g.scripts.Components()["character.breath_cooldown"].Get(g.player)

	if !found {
		t.Fatalf("Spit Poison did not start a cooldown: %v", before)
	}

	beforeRemaining, err := before.Get("remaining_aut")

	if err != nil ||
		beforeRemaining.(int64) <= 0 {
		t.Fatalf("invalid breath cooldown: %v, %v", beforeRemaining, err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	after, found := restored.scripts.Components()["character.breath_cooldown"].Get(restored.player)

	if !found {
		t.Fatal("restore lost breath cooldown")
	}

	afterRemaining, err := after.Get("remaining_aut")

	if err != nil ||
		afterRemaining != beforeRemaining {
		t.Fatalf("breath cooldown changed on restore: before=%v after=%v", before, after)
	}
}

func TestRestoreRejectsNegativeBreathCooldown(t *testing.T) {
	g := newStepGame(t)
	_, err := g.scripts.Components()["character.breath_cooldown"].Set(
		g.player,
		map[string]any{
			"remaining_aut": int64(-1),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if restored != nil {
		restored.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "breath cooldown") {
		t.Fatalf("negative breath cooldown was accepted: %v", err)
	}
}

func TestDemonicGuardianCooldownSurvivesSave(t *testing.T) {
	g := newStepGame(t)
	store := g.scripts.Components()["character.demonic_guardian"]

	_, err := store.Set(g.player, map[string]any{
		"cooldown_aut": int64(70),
	})

	if err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()
	state, found := restored.scripts.Components()["character.demonic_guardian"].Get(restored.player)

	if !found {
		t.Fatal("restore lost demonic guardian cooldown")
	}

	remaining, err := state.Get("cooldown_aut")

	if err != nil ||
		remaining != int64(70) {
		t.Fatalf("restored guardian cooldown = %v, %v", remaining, err)
	}
}

func TestRestoreRejectsNegativeDemonicGuardianCooldown(t *testing.T) {
	g := newStepGame(t)
	_, err := g.scripts.Components()["character.demonic_guardian"].Set(
		g.player,
		map[string]any{
			"cooldown_aut": int64(-1),
		},
	)

	if err != nil {
		t.Fatal(err)
	}

	restored, err := Restore(g.Snapshot())

	if restored != nil {
		restored.Close()
	}

	if err == nil ||
		!strings.Contains(err.Error(), "demonic guardian cooldown") {
		t.Fatalf("negative guardian cooldown was accepted: %v", err)
	}
}

func TestRollingChargeMovesThenAttacks(t *testing.T) {
	g := newStepGame(t)
	addPlayerMutation(t, g, "MUT_ROLL")

	target, found := g.levels[1].ActorAt(4, 1)

	if !found {
		t.Fatal("fixed Dungeon fixture has no charge target")
	}

	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_ROLLING_CHARGE",
		DX:        3,
	})

	if err != nil {
		t.Fatal(err)
	}

	position, _ := g.stores.Positions.Get(g.player)

	if result.Spent == 0 ||
		position.X != 3 ||
		position.Y != 1 {
		t.Fatalf("charge spent %d aut and ended at %d,%d", result.Spent,
			position.X, position.Y)
	}

	attacked := false

	for _, event := range result.Events {
		if strings.Contains(event.Text, "rat") &&
			(strings.Contains(event.Text, "You hit") ||
				strings.Contains(event.Text, "You miss")) {
			attacked = true
			break
		}
	}

	if !attacked {
		t.Fatalf("charge did not attack monster %d: %+v", target,
			result.Events)
	}

	dust := false

	for _, entity := range g.scripts.Components()["magic.cloud"].Entities() {
		cloud, found := g.scripts.Components()["magic.cloud"].Get(entity)

		if !found {
			continue
		}

		kind, err := cloud.Get("kind_id")

		if err != nil {
			t.Fatal(err)
		}

		if kind == "CLOUD_DUST" {
			dust = true
			break
		}
	}

	if !dust {
		t.Fatal("Rolling Charge left no source dust trail")
	}
}

func TestWordOfChaosWithoutVisibleTargetNeedsConfirmation(t *testing.T) {
	g := newStepGame(t)
	defer g.Close()

	addPlayerMutation(t, g, "MUT_WORD_OF_CHAOS")
	magic, _ := g.stores.Magic.Get(g.player)

	magic.Max = 10
	magic.Current = 10

	for _, monster := range g.stores.MonsterEnergy.Entities() {
		health, found := g.stores.Health.Get(monster)

		if found {
			health.Current = 0
		}
	}

	before := g.currentAut
	result, err := g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_WORD_OF_CHAOS",
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent != 0 || g.currentAut != before {
		t.Fatal("unconfirmed Word of Chaos spent time without targets")
	}

	if len(result.Events) == 0 ||
		!strings.Contains(result.Events[0].Text, "Speak a word of chaos anyway") {
		t.Fatalf("Word of Chaos omitted its confirmation: %+v", result.Events)
	}

	result, err = g.Step(Command{
		Kind:      CommandAbility,
		AbilityID: "ABIL_WORD_OF_CHAOS",
		Forced:    true,
	})

	if err != nil {
		t.Fatal(err)
	}

	if result.Spent == 0 {
		t.Fatal("confirmed Word of Chaos did not spend time")
	}
}
