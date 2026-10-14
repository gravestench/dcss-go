package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/game"
)

func TestWieldMenuBareHandsAndRecoveredWeapon(t *testing.T) {
	m := playingModel(t)
	start := m.game.View().CurrentAut
	m.handleKey("w")

	if m.screen != ScreenWield ||
		!strings.Contains(plainApp(m), "Wield which item?") {
		t.Fatalf("wield menu missing: %s", plainApp(m))
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != start {
		t.Fatal("wield cancel spent time")
	}

	m.handleKey("w")
	m.handleKey("-")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != start+3 {
		t.Fatalf("bare hands: screen=%d aut=%d", m.screen, m.game.View().CurrentAut)
	}

	m.handleKey("w")
	m.handleKey(inventoryLetter(t, m, "WPN_RAPIER"))

	if m.screen != ScreenPlay || m.game.View().CurrentAut != start+8 {
		t.Fatalf("re-wield: screen=%d aut=%d", m.screen, m.game.View().CurrentAut)
	}

	found := false

	for _, item := range m.game.View().Inventory {
		if item.KindID == "WPN_RAPIER" {
			found = item.Slot == "weapon"
		}
	}

	if !found {
		t.Fatal("re-wielded weapon is not shown as equipped")
	}
}

func TestWieldMenuKeepsInventoryLetters(t *testing.T) {
	canvas := NewCanvas(79, 24)
	view := game.View{
		Inventory: []game.ItemView{
			{
				Name:  "potion of might",
				Class: "OBJ_POTIONS",
			},

			{
				Name:  "rapier",
				Class: "OBJ_WEAPONS",
			},
		},
	}

	DrawWield(canvas, view)
	page := strings.Join(canvas.PlainRows(), "\n")

	if !strings.Contains(page, "b - rapier") ||
		strings.Contains(page, "a - rapier") ||
		!strings.Contains(page, "- - bare hands") {
		t.Fatalf("wield letters disagree with inventory: %s", page)
	}
}
