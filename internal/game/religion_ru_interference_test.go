package game

import (
	"reflect"
	"strings"
	"testing"

	"crawl/internal/ecs"
	"github.com/gravestench/akara"
)

// A live Ru worshipper and durable monster HP let several real attacks
// exercise the rare block and redirect decisions in one scenario seed.
func ruInterferenceGame(
	t *testing.T,
	kind string,
	playerX int,
	durable bool,
) (*Game, akara.Entity) {
	t.Helper()

	g := newStepGame(t)
	rat := ratID(t, g)
	actor, _ := g.stores.Actors.Get(rat)
	health, _ := g.stores.Health.Get(rat)
	playerHealth, _ := g.stores.Health.Get(g.player)

	actor.KindID = kind

	if durable {
		health.Current = 1000
		health.Max = 1000
	}

	playerHealth.Current = playerHealth.Max

	if err := g.levels[1].MoveActor(g.player, playerX, 1); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_RU",
			"piety":  int64(200),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["religion.ru"].Set(
		g.player, map[string]any{}); err != nil {
		t.Fatal(err)
	}

	return g, rat
}

// Keep a ranged or spell caster at its initial shot distance after an AI
// decision to walk. Its HP and the player's HP reset without touching RNG.
func resetRuAttacker(t *testing.T, g *Game, attacker akara.Entity) {
	t.Helper()

	position, _ := g.stores.Positions.Get(attacker)

	if position.X != 4 || position.Y != 1 {
		if err := g.levels[1].MoveActor(attacker, 4, 1); err != nil {
			t.Fatal(err)
		}
	}

	monsterHealth, _ := g.stores.Health.Get(attacker)
	playerHealth, _ := g.stores.Health.Get(g.player)

	monsterHealth.Current = monsterHealth.Max
	playerHealth.Current = playerHealth.Max
}

// Search the fixed seed's continuing religion stream until each actual
// melee outcome occurs. Blocking and self-redirection must spare the player.
func TestRuMeleeInterferenceBlocksAndRedirects(t *testing.T) {
	g, attacker := ruInterferenceGame(t, "MONS_ORC", 3, true)
	blocked := false
	redirected := false

	for attempt := 0; attempt < 200; attempt++ {
		resetRuAttacker(t, g, attacker)
		events, err := g.runAction(attacker, ecs.Intent{}, 0, "monster")

		if err != nil {
			t.Fatal(err)
		}

		interfered := false

		for _, event := range events {
			if strings.Contains(event.Text, "fails to attack") {
				blocked = true
				interfered = true
			}

			if strings.Contains(event.Text, "You redirect") {
				redirected = true
				interfered = true
			}
		}

		if interfered {
			playerHealth, _ := g.stores.Health.Get(g.player)

			if playerHealth.Current != playerHealth.Max {
				t.Fatal("Ru-interfered melee damaged the player")
			}
		}

		if blocked && redirected {
			break
		}
	}

	if !blocked || !redirected {
		t.Fatalf("Ru melee outcomes: blocked=%v redirected=%v",
			blocked, redirected)
	}

	if g.scripts.Components()["combat.forced_target"].Has(attacker) {
		t.Fatal("Ru melee left its forced target after the action")
	}
}

// A redirected launcher shot resolves against its monster target, then
// clears its temporary target before saving the continuing game.
func TestRuRangedInterferenceSurvivesRestore(t *testing.T) {
	g, attacker := ruInterferenceGame(t, "MONS_RAT", 1, false)
	giveTestMonsterItem(t, g, attacker, "WPN_SLING", "weapon", 1)
	redirected := false

	for attempt := 0; attempt < 250; attempt++ {
		resetRuAttacker(t, g, attacker)
		events, err := g.runAction(attacker, ecs.Intent{}, 0, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			redirected = redirected ||
				strings.Contains(event.Text, "You redirect")
		}

		if redirected {
			break
		}
	}

	if !redirected || g.turn.ResolvedIntent != ecs.IntentRanged {
		t.Fatal("rat never redirected a real launcher shot")
	}

	if g.scripts.Components()["combat.forced_target"].Has(attacker) {
		t.Fatal("Ru ranged shot left its forced target")
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	if playerHealth.Current != playerHealth.Max {
		t.Fatal("redirected shot damaged the player")
	}

	snapshot := g.Snapshot()
	restored, err := Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	defer restored.Close()

	if !reflect.DeepEqual(snapshot, restored.Snapshot()) {
		t.Fatal("Ru redirected shot changed on restore")
	}
}

// The thrown-ammunition route uses the same Ru decision as launchers, but
// applies its contact and coating to a monster rather than the player.
func TestRuRedirectsThrownPoisonDart(t *testing.T) {
	g, attacker := ruInterferenceGame(t, "MONS_KOBOLD", 1, true)
	missileID := giveTestMonsterItem(t, g, attacker,
		"MI_DART", "missile", 4)
	missile, _ := g.stores.Items.Get(missileID)

	missile.Ego = "poisoned"

	redirected := false

	for attempt := 0; attempt < 500; attempt++ {
		resetRuAttacker(t, g, attacker)
		events, err := g.runAction(attacker, ecs.Intent{}, 0,
			"monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			redirected = redirected ||
				strings.Contains(event.Text, "You redirect")
		}

		if redirected {
			break
		}
	}

	if !redirected || g.turn.ResolvedIntent != ecs.IntentRanged {
		t.Fatal("Ru never redirected a thrown poison dart")
	}

	if g.scripts.Components()["combat.forced_target"].Has(attacker) {
		t.Fatal("redirected dart left a forced target")
	}

	playerHealth, _ := g.stores.Health.Get(g.player)

	if playerHealth.Current != playerHealth.Max {
		t.Fatal("redirected dart damaged the player")
	}
}

// Ru interrupts an actual book cast, retaining spell energy cost while
// suppressing the spell effect and leaving no temporary target component.
func TestRuSpellInterferenceConsumesSpellEnergy(t *testing.T) {
	g, caster := ruInterferenceGame(t, "MONS_ORC_WIZARD", 1, true)
	blocked := false

	for attempt := 0; attempt < 300; attempt++ {
		resetRuAttacker(t, g, caster)
		events, err := g.runAction(caster, ecs.Intent{}, 0, "monster")

		if err != nil {
			t.Fatal(err)
		}

		for _, event := range events {
			blocked = blocked ||
				strings.Contains(event.Text,
					"begins to cast a spell, but is stunned")
		}

		if blocked {
			break
		}
	}

	if !blocked || g.turn.ResolvedIntent != ecs.IntentSpell {
		t.Fatal("Ru never interrupted a real spell cast")
	}

	energy, _ := g.stores.MonsterEnergy.Get(caster)

	energy.Points = 100

	if err := g.scheduler.Spend(caster, ecs.Intent{
		Kind: ecs.IntentSpell,
	}); err != nil {
		t.Fatal(err)
	}

	if energy.Points >= 100 {
		t.Fatal("Ru-interrupted spell spent no spell energy")
	}

	if g.scripts.Components()["combat.forced_target"].Has(caster) {
		t.Fatal("Ru-interrupted cast left a forced target")
	}
}

// A second hostile body gives the redirected spell chooser a real target.
// The completed cast must clear the same-side override after resolution.
func TestRuSpellInterferenceRedirectsCompletedCast(t *testing.T) {
	g, caster := ruInterferenceGame(t, "MONS_ORC_WIZARD", 1, true)

	// One-star Ru keeps attack interference active without the separate
	// two-star retaliation power interrupting repeated spell attempts.
	if _, err := g.scripts.Components()["religion.worship"].Set(
		g.player,
		map[string]any{
			"god_id": "GOD_RU",
			"piety":  int64(49),
		},
	); err != nil {
		t.Fatal(err)
	}

	if _, err := g.scripts.Components()["vault.actor_overrides"].Set(
		caster,
		map[string]any{
			"spells": []any{"throw_flame.200.wizard"},
		},
	); err != nil {
		t.Fatal(err)
	}

	victim, err := g.world.CreateEntity()

	if err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Actors.Set(victim, ecs.Actor{
		KindID: "MONS_ORC",
		Speed:  10,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Health.Set(victim, ecs.Health{
		Current: 1000,
		Max:     1000,
	}); err != nil {
		t.Fatal(err)
	}

	if _, err := g.stores.Combat.Set(victim, ecs.Combatant{}); err != nil {
		t.Fatal(err)
	}

	if err := g.levels[1].PlaceActor(victim, 2, 3); err != nil {
		t.Fatal(err)
	}

	completed := false
	redirectCount := 0
	spellCount := 0
	meleeCount := 0
	moveCount := 0
	var lastRedirect []Event

	for attempt := 0; attempt < 600; attempt++ {
		resetRuAttacker(t, g, caster)
		events, actionErr := g.runAction(caster, ecs.Intent{}, 0, "monster")

		if actionErr != nil {
			t.Fatal(actionErr)
		}

		redirected := false

		for _, event := range events {
			redirected = redirected ||
				strings.Contains(event.Text, "You redirect")
		}

		if redirected && g.turn.ResolvedIntent == ecs.IntentSpell {
			completed = true

			break
		}

		if redirected {
			redirectCount++
			lastRedirect = events
		}

		if g.turn.ResolvedIntent == ecs.IntentSpell {
			spellCount++
		}

		if g.turn.ResolvedIntent == ecs.IntentMelee {
			meleeCount++
		}

		if g.turn.ResolvedIntent == ecs.IntentMove {
			moveCount++
		}
	}

	if !completed {
		ai, _ := g.stores.AI.Get(caster)
		position, _ := g.stores.Positions.Get(caster)

		t.Fatalf("Ru never completed a redirected monster cast: "+
			"redirects=%d spells=%d melee=%d move=%d ai=%+v pos=%+v last=%+v",
			redirectCount, spellCount, meleeCount, moveCount,
			ai, position, lastRedirect)
	}

	if g.scripts.Components()["combat.forced_target"].Has(caster) {
		t.Fatal("Ru cast left its same-side target override")
	}
}
