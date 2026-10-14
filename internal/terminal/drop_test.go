package terminal

import (
	"strings"
	"testing"
)

func inventoryLetter(t *testing.T, m *AppModel, kindID string) string {
	t.Helper()

	for index, item := range m.game.View().Inventory {
		if item.KindID == kindID {
			return string(menuLetter(index))
		}
	}

	t.Fatalf("inventory item %s missing", kindID)

	return ""
}

func TestDropMenuSelectsItemAndQuantityWithoutSpendingOnCancel(t *testing.T) {
	m := playingModel(t)
	start := m.game.View().CurrentAut
	m.handleKey("d")

	if m.screen != ScreenDrop ||
		!strings.Contains(plainApp(m), "Drop which item?") {
		t.Fatalf("drop menu missing: %s", plainApp(m))
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != start {
		t.Fatal("drop cancel spent time")
	}

	m.handleKey("d")
	m.handleKey(inventoryLetter(t, m, "ARM_SCALE_MAIL"))

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut != start ||
		!strings.Contains(m.notice, "take that off") {
		t.Fatalf("equipped armour drop: screen=%d aut=%d notice=%q", m.screen, m.game.View().CurrentAut, m.notice)
	}

	m.handleKey("d")
	m.handleKey("2")

	if !strings.Contains(plainApp(m), "quantity: 2") {
		t.Fatal("drop quantity is not displayed")
	}

	m.handleKey(inventoryLetter(t, m, "POT_MIGHT"))

	if m.screen != ScreenPlay || m.game.View().CurrentAut != start+10 {
		t.Fatalf("potion drop: screen=%d aut=%d", m.screen, m.game.View().CurrentAut)
	}

	for _, item := range m.game.View().Inventory {
		if item.KindID == "POT_MIGHT" {
			t.Fatal("dropped potion remained in inventory")
		}
	}
}
