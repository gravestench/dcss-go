package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

func TestBarachiHopOpensSourceAbilityMenuAndAim(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_BARACHI",
		"JOB_FIGHTER",
		"WPN_WAR_AXE",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	m.game = g
	m.screen = ScreenPlay

	before := g.View().CurrentAut

	m.handleKey("a")

	if m.screen != ScreenAbilities {
		t.Fatalf("a opened screen %v, want abilities", m.screen)
	}

	if rows := strings.Join(m.renderCanvas().PlainRows(), "\n"); !strings.Contains(rows, "Hop") {
		t.Fatalf("ability menu omitted innate Hop:\n%s", rows)
	}

	m.handleKey("a")

	if m.screen != ScreenAim ||
		m.aimKind != game.CommandAbility ||
		m.aimAbilityID != "ABIL_HOP" {
		t.Fatal("selecting Hop did not start ability aiming")
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || g.View().CurrentAut != before {
		t.Fatal("cancelled ability aim changed game time")
	}
}

func TestAbilityConfirmationCanCancelWithoutSpendingTime(t *testing.T) {
	m := playingModel(t)

	m.screen = ScreenAbilities

	before := m.game.View().CurrentAut

	m.applyInputDecision(map[string]any{
		"action":     "confirm_ability",
		"ability_id": "ABIL_WORD_OF_CHAOS",
	})

	if m.screen != ScreenAbilityConfirm {
		t.Fatal("Word of Chaos did not open its confirmation screen")
	}

	if rows := strings.Join(m.renderCanvas().PlainRows(), "\n"); !strings.Contains(rows, "Speak a word of chaos anyway?") {
		t.Fatalf("confirmation omitted the source prompt:\n%s", rows)
	}

	m.handleKey("n")

	if m.screen != ScreenAbilities || m.game.View().CurrentAut != before {
		t.Fatal("declining Word of Chaos changed the game turn")
	}
}
