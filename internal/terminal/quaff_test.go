package terminal

import (
	"strings"
	"testing"

	"dcrawl-go/internal/ecs"
	"dcrawl-go/internal/game"
	"dcrawl-go/internal/save"
	"github.com/gravestench/akara"
)

func potionLetter(t *testing.T, m *AppModel, kind string) string {
	t.Helper()

	for i, item := range m.game.View().Inventory {
		if item.KindID == kind {
			return string(menuLetter(i))
		}
	}

	t.Fatalf("no carried %s", kind)

	return ""
}

func TestQuaffChoiceCancelAndStartingMight(t *testing.T) {
	m := playingModel(t)
	aut := m.game.View().CurrentAut
	m.handleKey("q")

	if m.screen != ScreenQuaff ||
		!strings.Contains(plainApp(m), "Quaff which potion?") {
		t.Fatalf("q screen %d: %s", m.screen, plainApp(m))
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != aut {
		t.Fatal("cancel spent time")
	}

	m.handleKey("q")
	m.handleKey(potionLetter(t, m, "POT_MIGHT"))

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut != aut+10 ||
		m.game.View().MightAut < 340 ||
		m.notice != "" {
		t.Fatalf(
			"might potion: screen %d notice %q time %d, might %d",
			m.screen,
			m.notice,
			m.game.View().CurrentAut,
			m.game.View().MightAut,
		)
	}

	if !strings.Contains(plainApp(m), "Might") {
		t.Fatal("might status light is missing")
	}
}

func TestQuaffHasteFromInventoryShowsFastLight(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()
	var lastID uint64

	for _, record := range snapshot.Entities {
		lastID = max(lastID, record.ID)
	}

	snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
		ID: lastID + 1,
		Item: &ecs.Item{
			KindID:   "POT_HASTE",
			Quantity: 1,
		},

		CarriedBy: &ecs.CarriedBy{
			Holder: akara.Entity(snapshot.PlayerID),
		},
	})

	loaded, err := game.Restore(snapshot, m.catalog)

	if err != nil {
		t.Fatal(err)
	}

	m.game.Close()
	m.game = loaded
	m.handleKey("q")
	m.handleKey(potionLetter(t, m, "POT_HASTE"))

	if m.screen != ScreenPlay ||
		m.notice != "" ||
		m.game.View().HasteAut == 0 ||
		!strings.Contains(plainApp(m), "Fast") {
		t.Fatalf("haste quaff screen %d, notice %q, duration %d",
			m.screen, m.notice, m.game.View().HasteAut)
	}
}

func TestQuaffSelectedCuringFromPickedUpInventory(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()
	var curing *ecs.Position

	for i := range snapshot.Entities {
		record := &snapshot.Entities[i]

		if record.Item != nil && record.Item.KindID == "POT_CURING" {
			curing = record.Position

			break
		}
	}

	if curing == nil {
		t.Fatal("generated run has no curing potion")
	}

	for i := range snapshot.Entities {
		record := &snapshot.Entities[i]

		if record.ID == snapshot.PlayerID {
			record.Position = &ecs.Position{
				LevelID: curing.LevelID,
				X:       curing.X,
				Y:       curing.Y,
			}

			break
		}
	}

	restored, err := game.Restore(snapshot, m.catalog)

	if err != nil {
		t.Fatal(err)
	}

	m.game.Close()
	m.game = restored

	if _, err := m.game.Step(game.Command{Kind: game.CommandPickup}); err != nil {
		t.Fatal(err)
	}

	aut := m.game.View().CurrentAut
	letter := potionLetter(t, m, "POT_CURING")
	m.handleKey("q")

	if m.screen != ScreenQuaff ||
		!strings.Contains(plainApp(m), "potion of curing") {
		t.Fatalf("curing absent from quaff list: %s", plainApp(m))
	}

	m.handleKey(letter)

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut != aut+10 ||
		m.notice != "" {
		t.Fatalf("curing choice: screen %d notice %q time %d", m.screen, m.notice, m.game.View().CurrentAut)
	}

	for _, item := range m.game.View().Inventory {
		if item.KindID == "POT_CURING" {
			t.Fatal("curing potion still in pack")
		}
	}
}

func TestQuaffHealWoundsInventoryLetter(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()

	for i := range snapshot.Entities {
		record := &snapshot.Entities[i]

		if record.ID == snapshot.PlayerID {
			record.Health.Current = 1
		}

		if record.Item != nil && record.Item.KindID == "POT_HEAL_WOUNDS" {
			record.Position = nil
			record.CarriedBy = &ecs.CarriedBy{Holder: akara.Entity(snapshot.PlayerID)}
		}
	}

	restored, err := game.Restore(snapshot, m.catalog)

	if err != nil {
		t.Fatal(err)
	}

	m.game.Close()
	m.game = restored

	before := m.game.View().CurrentAut
	m.handleKey("q")

	if m.screen != ScreenQuaff ||
		!strings.Contains(plainApp(m), "potion of heal wounds") {
		t.Fatalf("heal wounds missing from quaff menu: %s", plainApp(m))
	}

	m.handleKey(potionLetter(t, m, "POT_HEAL_WOUNDS"))

	if m.screen != ScreenPlay ||
		m.game.View().CurrentAut != before+10 ||
		m.game.View().PlayerHP <= 1 ||
		m.notice != "" {
		t.Fatalf("heal wounds choice: screen %d notice %q view %+v", m.screen, m.notice, m.game.View())
	}
}
