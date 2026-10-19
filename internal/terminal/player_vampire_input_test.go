package terminal

import (
	"strings"
	"testing"

	"crawl/internal/game"
)

func TestVampireAbilityMenuRunsBloodRitual(t *testing.T) {
	m := pregameModel(t)
	g, err := game.NewDungeonGame(
		43,
		"SP_VAMPIRE",
		"JOB_FIGHTER",
		"WPN_RAPIER",
		"Tester",
	)

	if err != nil {
		t.Fatal(err)
	}

	defer g.Close()
	m.game = g
	m.screen = ScreenPlay
	m.handleKey("a")

	if m.screen != ScreenAbilities {
		t.Fatalf("Vampire ability screen = %v", m.screen)
	}

	if rows := strings.Join(m.renderCanvas().PlainRows(), "\n"); !strings.Contains(rows, "Exsanguinate") {
		t.Fatalf("Vampire ability menu lacks Exsanguinate:\n%s", rows)
	}

	m.handleKey("a")

	if m.screen != ScreenPlay || g.View().VampireRitualRemaining != 50 {
		t.Fatalf("blood ritual not scheduled: screen %v, remaining %d",
			m.screen, g.View().VampireRitualRemaining)
	}

	for range 5 {
		m.Update(vampireTick{id: m.vampireTickID})
	}

	if g.View().VampireRitualRemaining != 0 {
		t.Fatal("blood ritual did not finish on scheduled ticks")
	}

	if !strings.Contains(plainApp(m), "Bloodless") {
		t.Fatal("bloodless HUD status is missing")
	}

	m.handleKey("a")
	m.handleKey("a")

	if g.View().VampireRitualRemaining != 50 {
		t.Fatal("Revivify did not start")
	}

	beforeCancel := g.View().CurrentAut
	staleTick := m.vampireTickID

	m.handleKey("esc")
	m.Update(vampireTick{id: staleTick})

	if g.View().VampireRitualRemaining != 0 ||
		g.View().CurrentAut != beforeCancel {
		t.Fatal("cancelling Revivify or its stale tick spent time")
	}
}
