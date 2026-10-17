package terminal

import (
	"fmt"
	"sort"

	tea "charm.land/bubbletea/v2"
	"dcrawl-go/internal/game"
)

func (m *AppModel) openShop() {
	m.screen = ScreenShop
	m.shopSort = "type"
	m.shopSelected = make(map[uint64]game.ShopSelection)
	m.shopFocus = 0
	m.shopConfirming = false
	m.notice = ""
}

func (m *AppModel) shopView() (game.ShopView, bool) {
	view, err := m.game.ShopAtPlayer(m.shopSort)

	if err != nil {
		m.notice = fmt.Sprintf("Shop failed: %v", err)

		return game.ShopView{}, false
	}

	if !view.Available {
		m.screen = ScreenPlay
		m.notice = "There is no shop here."

		return game.ShopView{}, false
	}

	if m.shopFocus >= len(view.Items) {
		m.shopFocus = max(0, len(view.Items)-1)
	}

	return view, true
}

func (m *AppModel) selectedShopStock() ([]game.ShopSelection, int64) {
	selection := make([]game.ShopSelection, 0, len(m.shopSelected))
	var total int64

	for _, item := range m.shopSelected {
		selection = append(selection, item)
		total += item.Price
	}

	sort.Slice(selection, func(left, right int) bool {
		return selection[left].ID < selection[right].ID
	})

	return selection, total
}

func (m *AppModel) shopSelectionChanged(view game.ShopView) bool {
	for _, selected := range m.shopSelected {
		found := false

		for _, item := range view.Items {
			if item.ID == selected.ID &&
				item.Price == selected.Price &&
				item.Quantity == selected.Quantity &&
				item.Signature == selected.Signature {
				found = true
				break
			}
		}

		if !found {
			return true
		}
	}

	return false
}

func shopInputItems(view game.ShopView) []any {
	items := make([]any, 0, len(view.Items))

	for _, item := range view.Items {
		items = append(items, map[string]any{
			"id":     item.ID,
			"letter": item.Letter,
		})
	}

	return items
}

func (m *AppModel) handleShopKey(key string) tea.Cmd {
	view, ok := m.shopView()

	if !ok {
		return nil
	}

	decision, err := m.presentationRuntime.PolicyReadOnly(
		"terminal.shop_input", map[string]any{
			"key":        key,
			"confirming": m.shopConfirming,
			"items":      shopInputItems(view),
		})

	if err != nil {
		m.notice = fmt.Sprintf("Shop input failed: %v", err)

		return nil
	}

	m.applyShopDecision(view, decision)

	return nil
}

func (m *AppModel) applyShopDecision(view game.ShopView, decision map[string]any) {
	action, _ := decision["action"].(string)
	selection, total := m.selectedShopStock()

	switch action {
	case "close":
		m.screen = ScreenPlay
		m.shopConfirming = false
		m.notice = ""

	case "toggle":
		id, ok := decision["id"].(int64)

		if ok && id > 0 {
			m.toggleShopSelection(view, uint64(id))
		}

	case "focus":
		delta, _ := decision["delta"].(int64)
		focus := m.shopFocus + int(delta)

		m.shopFocus = max(0, min(len(view.Items)-1, focus))

	case "sort":
		m.shopSort = nextShopSort(m.shopSort)
		m.notice = ""

	case "confirm":
		if len(selection) == 0 {
			m.notice = "Select an item to buy."
		} else if m.shopSelectionChanged(view) {
			m.shopSelected = make(map[uint64]game.ShopSelection)
			m.notice = "Shop stock changed. Select the items again."
		} else if total > view.Gold {
			m.notice = "You do not have enough gold."
		} else {
			m.shopConfirming = true
			m.notice = ""
		}

	case "cancel_confirm":
		m.shopConfirming = false

	case "buy":
		m.buyShopSelection(view.ID, selection)

	case "toggle_focus":
		if len(view.Items) > 0 {
			m.toggleShopSelection(view, view.Items[m.shopFocus].ID)
		}

	case "list":
		m.toggleFocusedShopList(view)

	case "examine":
		if len(view.Items) > 0 {
			m.notice = view.Items[m.shopFocus].Name
		}

	case "help":
		m.notice = "Letters select stock; Enter buys; $ marks a shopping list item."
	}
}

func (m *AppModel) toggleShopSelection(view game.ShopView, id uint64) {
	if _, found := m.shopSelected[id]; found {
		delete(m.shopSelected, id)
		m.notice = ""

		return
	}

	for _, item := range view.Items {
		if item.ID == id {
			m.shopSelected[id] = game.ShopSelection{
				ID:        id,
				Price:     item.Price,
				Quantity:  item.Quantity,
				Signature: item.Signature,
			}

			m.notice = ""

			return
		}
	}
}

func nextShopSort(current string) string {
	switch current {
	case "type":
		return "price"

	case "price":
		return "name"

	default:
		return "type"
	}
}

func (m *AppModel) buyShopSelection(
	shopID uint64,
	selection []game.ShopSelection,
) {
	if len(selection) == 0 {
		m.shopConfirming = false
		m.notice = "Select an item to buy."

		return
	}

	purchase, err := m.game.BuyShopSelection(shopID, selection)

	m.shopConfirming = false

	if err != nil {
		m.notice = fmt.Sprintf("Purchase failed: %v", err)

		return
	}

	m.shopSelected = make(map[uint64]game.ShopSelection)
	m.notice = fmt.Sprintf("You spent %d gold.", purchase.Spent)
}

func (m *AppModel) toggleFocusedShopList(view game.ShopView) {
	if len(view.Items) == 0 {
		m.notice = "This shop is empty."

		return
	}

	item := view.Items[m.shopFocus]
	listed, err := m.game.ToggleShopList(view.ID, item.ID)

	if err != nil {
		m.notice = fmt.Sprintf("Shopping list failed: %v", err)

		return
	}

	if listed {
		m.notice = "Added to shopping list."
	} else {
		m.notice = "Removed from shopping list."
	}
}

func (m *AppModel) drawShop(canvas *Canvas) {
	view, ok := m.shopView()

	if !ok {
		return
	}

	_, total := m.selectedShopStock()
	items := make([]any, 0, len(view.Items))

	for _, item := range view.Items {
		_, selected := m.shopSelected[item.ID]

		items = append(items, map[string]any{
			"id":       item.ID,
			"name":     item.Name,
			"letter":   item.Letter,
			"quantity": item.Quantity,
			"price":    item.Price,
			"on_list":  item.OnList,
			"selected": selected,
		})
	}

	result := runPresentation(m.presentationPolicy, "presentation.shop", map[string]any{
		"name":           view.Name,
		"gold":           view.Gold,
		"sort":           view.Sort,
		"items":          items,
		"selected_total": total,
		"confirming":     m.shopConfirming,
		"focus":          m.shopFocus + 1,
		"notice":         m.notice,
		"width":          canvas.width,
		"height":         canvas.height,
	})

	drawPresentation(canvas, fullRegion(canvas), result)
}
