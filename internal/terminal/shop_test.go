package terminal

import (
	"encoding/json"
	"strings"
	"testing"

	"crawl/internal/game"
)

func shopModel(t *testing.T) *AppModel {
	t.Helper()
	m := pregameModel(t)
	g, err := game.NewShopScenario(17, "WPN_RAPIER", "Alice")

	if err != nil {
		t.Fatal(err)
	}

	snapshot := g.Snapshot()
	g.Close()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.ID != snapshot.PlayerID {
			continue
		}

		record.Position.X = 3
		record.Position.Y = 2

		for component := range record.Dynamic {
			if record.Dynamic[component].Schema == "character.wallet" {
				record.Dynamic[component].Values["gold"] =
					json.RawMessage("10000")
			}
		}
	}

	m.game, err = game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	m.screen = ScreenPlay

	return m
}

func TestShopScreenPurchaseAndTerminalSizing(t *testing.T) {
	m := shopModel(t)
	pressApp(m, ">")

	if m.screen != ScreenShop {
		t.Fatalf("shop did not open: screen %d, notice %q",
			m.screen, m.notice)
	}

	page := plainApp(m)

	for _, want := range []string{
		"General Store",
		"Gold: 10000",
		"club",
		"buckler",
		"potion of curing",
		"gold",
	} {
		if !strings.Contains(page, want) {
			t.Fatalf("shop missing %q: %s", want, page)
		}
	}

	pressApp(m, "!")

	if sorted := plainApp(m); !strings.Contains(sorted, "Sort: price") {
		t.Fatal("shop sort key did not change the stock order mode")
	}

	pressApp(m, "!")
	pressApp(m, "!")
	pressApp(m, "$")

	if listed := plainApp(m); !strings.Contains(listed, "$ ") {
		t.Fatal("shopping-list marker was not rendered")
	}

	pressApp(m, "x")

	if m.notice == "" {
		t.Fatal("shop examine key did not show the focused item")
	}

	pressApp(m, "a")
	pressApp(m, "enter")

	if !m.shopConfirming {
		t.Fatalf("shop purchase confirmation did not open: notice %q, selected %+v",
			m.notice, m.shopSelected)
	}

	pressApp(m, "n")

	if m.shopConfirming {
		t.Fatal("declining purchase did not close the confirmation")
	}

	pressApp(m, "enter")

	pressApp(m, "y")

	if m.screen != ScreenShop || m.shopConfirming {
		t.Fatal("purchase did not return to shop stock")
	}

	view, err := m.game.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if view.Gold >= 10000 || len(view.Items) != 2 {
		t.Fatalf("purchase did not change wallet and stock: %+v", view)
	}

	m.width = 110
	m.height = 35

	if wide := plainApp(m); !strings.Contains(wide, "General Store") {
		t.Fatal("wide shop rendering lost its header")
	}
}

func TestShopScreenRejectsMissingSelectedStock(t *testing.T) {
	m := shopModel(t)
	pressApp(m, ">")
	view, err := m.game.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	first := view.Items[0]

	m.shopSelected = map[uint64]game.ShopSelection{
		first.ID: {
			ID:        first.ID,
			Price:     first.Price,
			Quantity:  first.Quantity,
			Signature: first.Signature,
		},

		999999: {
			ID:        999999,
			Price:     1,
			Quantity:  1,
			Signature: "stale",
		},
	}

	pressApp(m, "enter")

	if m.shopConfirming || !strings.Contains(m.notice, "changed") {
		t.Fatalf("partial shop selection was accepted: %q", m.notice)
	}

	after, err := m.game.ShopAtPlayer("type")

	if err != nil {
		t.Fatal(err)
	}

	if after.Gold != view.Gold || len(after.Items) != len(view.Items) {
		t.Fatal("rejected selection changed wallet or stock")
	}
}

func TestWalkingOntoShopOpensStockScreen(t *testing.T) {
	m := shopModel(t)
	snapshot := m.game.Snapshot()
	m.game.Close()

	for index := range snapshot.Entities {
		record := &snapshot.Entities[index]

		if record.ID == snapshot.PlayerID {
			record.Position.X = 3
			record.Position.Y = 1
		}
	}

	var err error
	m.game, err = game.Restore(snapshot)

	if err != nil {
		t.Fatal(err)
	}

	m.screen = ScreenPlay
	m.stepPlayCommand(game.Command{
		Kind: game.CommandMove,
		DY:   1,
	})

	if m.screen != ScreenShop {
		t.Fatalf("walking onto shop did not open stock: %q", m.notice)
	}
}
