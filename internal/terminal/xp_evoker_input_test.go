package terminal

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/game"
	"crawl/internal/save"
	"github.com/gravestench/akara"
)

func TestSourceXPEvokerKeyOpensMenuAndAims(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()
	snapshot.EntityCursor++
	snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
		ID: snapshot.EntityCursor,
		Item: &ecs.Item{
			KindID:   "MISC_LIGHTNING_ROD",
			Quantity: 1,
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
	for _, item := range m.game.View().Inventory {
		if item.KindID == "MISC_LIGHTNING_ROD" &&
			!strings.Contains(item.Name, "4/4") {
			t.Fatalf("full lightning rod has no charge label: %q", item.Name)
		}
	}

	m.handleKey("v")
	if m.screen != ScreenEvokeItem ||
		!strings.Contains(plainApp(m), "Evoke which item?") {
		t.Fatalf("v did not open evoker menu: screen=%d", m.screen)
	}

	m.handleKey("esc")
	if m.screen != ScreenPlay || m.game.View().CurrentAut != beforeAut {
		t.Fatal("cancelling evoker selection spent time")
	}

	m.handleKey("v")
	m.handleKey(potionLetter(t, m, "MISC_LIGHTNING_ROD"))
	if m.screen != ScreenAim || m.aimKind != game.CommandEvokeItem {
		t.Fatalf("evoker choice did not start aim: screen=%d kind=%d",
			m.screen, m.aimKind)
	}
}
