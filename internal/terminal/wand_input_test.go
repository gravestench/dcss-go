package terminal

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/game"
	"crawl/internal/save"
	"github.com/gravestench/akara"
)

func TestSourceWandKeyOpensMenuAndAims(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()
	var lastID uint64

	for _, record := range snapshot.Entities {
		lastID = max(lastID, record.ID)
	}

	snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
		ID: lastID + 1,
		Item: &ecs.Item{
			KindID:   "WAND_DIGGING",
			Quantity: 1,
			Charges:  1,
		},

		CarriedBy: &ecs.CarriedBy{
			Holder: akara.Entity(snapshot.PlayerID),
		},
	})

	loaded, err := game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	m.game.Close()
	m.game = loaded

	beforeAut := m.game.View().CurrentAut

	m.handleKey("V")

	if m.screen != ScreenEvokeWand ||
		!strings.Contains(plainApp(m), "Evoke which wand?") {
		t.Fatalf("V did not open wand menu: screen=%d", m.screen)
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != beforeAut {
		t.Fatal("cancelling wand selection spent time")
	}

	m.handleKey("V")
	m.handleKey(potionLetter(t, m, "WAND_DIGGING"))

	if m.screen != ScreenAim || m.aimKind != game.CommandEvokeWand {
		t.Fatalf("wand choice did not start aim: screen=%d kind=%d",
			m.screen, m.aimKind)
	}

	m.handleKey("enter")

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut != beforeAut+10 {
		t.Fatalf("wand did not spend a turn: screen=%d time=%d",
			m.screen, m.game.View().CurrentAut)
	}

	for _, item := range m.game.View().Inventory {
		if item.KindID == "WAND_DIGGING" {
			t.Fatal("used last wand charge remains in inventory")
		}
	}
}
