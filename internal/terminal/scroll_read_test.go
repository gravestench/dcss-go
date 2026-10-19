package terminal

import (
	"strings"
	"testing"

	"crawl/internal/ecs"
	"crawl/internal/game"
	"crawl/internal/save"
	"github.com/gravestench/akara"
)

func TestReadSelectionShowsVisibleNamesAndOneAction(t *testing.T) {
	m := playingModel(t)
	snapshot := m.game.Snapshot()
	var highest uint64

	for _, entity := range snapshot.Entities {
		if entity.ID > highest {
			highest = entity.ID
		}
	}

	for _, kind := range []string{
		"SCR_IDENTIFY",
		"SCR_IDENTIFY",
		"POT_CURING",
	} {
		highest++
		snapshot.Entities = append(snapshot.Entities, save.EntityRecord{
			ID: highest,
			Item: &ecs.Item{
				KindID:   kind,
				Quantity: 1,
			},
			CarriedBy: &ecs.CarriedBy{
				Holder: akara.Entity(snapshot.PlayerID),
			},
		})
	}

	restored, err := game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	m.game = restored

	readIdentify := func() {
		t.Helper()
		m.handleKey("r")

		for index, item := range m.game.View().Inventory {
			if item.KindID == "SCR_IDENTIFY" {
				m.handleKey(string(rune('a' + index)))

				return
			}
		}

		t.Fatal("identify scroll missing from inventory")
	}

	before := m.game.View().CurrentAut
	readIdentify()

	if m.screen != ScreenSelection ||
		!strings.Contains(plainApp(m), "Identify which item?") {
		t.Fatalf("read selection screen %d: %s", m.screen, plainApp(m))
	}

	m.handleKey("esc")

	if m.game.View().CurrentAut != before+10 {
		t.Fatal("unknown cancelled identify did not use exactly one turn")
	}

	readIdentify()
	m.handleKey("esc")

	if m.game.View().CurrentAut != before+10 {
		t.Fatal("known cancelled identify spent time")
	}

	readIdentify()

	if m.screen != ScreenSelection {
		t.Fatalf("known identify omitted selection: %d", m.screen)
	}

	for index, option := range m.pendingSelection.Options {
		if strings.Contains(option.Label, "potion") {
			m.handleKey(string(rune('a' + index)))
			break
		}
	}

	if m.game.View().CurrentAut != before+20 {
		t.Fatal("selected identify did not use exactly one turn")
	}
}

func TestReadKeyOpensScrollInventoryAndCancelIsFree(t *testing.T) {
	m := playingModel(t)
	before := m.game.View().CurrentAut

	m.handleKey("r")

	if m.screen != ScreenRead ||
		!strings.Contains(plainApp(m), "Read which scroll?") {
		t.Fatalf("read screen %d: %s", m.screen, plainApp(m))
	}

	m.handleKey("esc")

	if m.screen != ScreenPlay || m.game.View().CurrentAut != before {
		t.Fatal("cancelling the read menu spent time")
	}
}
