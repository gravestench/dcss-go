package game

import (
	"fmt"
)

// ShopItemView is the screen-neutral projection of one saved stock entity.
type ShopItemView struct {
	ID        uint64
	Name      string
	Class     string
	Letter    string
	Quantity  int
	Price     int64
	OnList    bool
	Signature string
}

type ShopView struct {
	Available bool
	ID        uint64
	Name      string
	Gold      int64
	Sort      string
	Items     []ShopItemView
}

type ShopPurchase struct {
	Spent    int64
	Acquired []uint64
	Outside  []uint64
}

// ShopSelection freezes the displayed quote and quantity until confirmation.
type ShopSelection struct {
	ID        uint64
	Price     int64
	Quantity  int
	Signature string
}

func shopInteger(record map[string]any, key string) (int64, error) {
	value, ok := record[key].(int64)

	if !ok || value < 0 {
		return 0, fmt.Errorf("shop %s is not a nonnegative integer", key)
	}

	return value, nil
}

func shopIDs(value any, field string) ([]uint64, error) {
	if empty, ok := value.(map[string]any); ok && len(empty) == 0 {
		return []uint64{}, nil
	}

	entries, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("shop %s is not a list", field)
	}

	ids := make([]uint64, 0, len(entries))

	for _, entry := range entries {
		id, ok := entry.(int64)

		if !ok || id <= 0 {
			return nil, fmt.Errorf("shop %s has invalid entity ID", field)
		}

		ids = append(ids, uint64(id))
	}

	return ids, nil
}

func shopItems(value any) ([]ShopItemView, error) {
	if empty, ok := value.(map[string]any); ok && len(empty) == 0 {
		return []ShopItemView{}, nil
	}

	entries, ok := value.([]any)

	if !ok {
		return nil, fmt.Errorf("shop items is not a list")
	}

	items := make([]ShopItemView, 0, len(entries))

	for _, entry := range entries {
		fields, ok := entry.(map[string]any)

		if !ok {
			return nil, fmt.Errorf("shop item is not a record")
		}

		id, err := shopInteger(fields, "id")

		if err != nil {
			return nil, err
		}

		if id == 0 {
			return nil, fmt.Errorf("shop item has invalid ID")
		}

		price, err := shopInteger(fields, "price")

		if err != nil {
			return nil, err
		}

		quantity, err := shopInteger(fields, "quantity")

		if err != nil {
			return nil, err
		}

		if quantity == 0 {
			return nil, fmt.Errorf("shop item has invalid quantity")
		}

		name, named := fields["name"].(string)
		class, classified := fields["class"].(string)
		letter, lettered := fields["letter"].(string)
		onList, listed := fields["on_list"].(bool)
		signature, signed := fields["signature"].(string)

		if !named ||
			name == "" ||
			!classified ||
			!lettered ||
			!listed ||
			!signed ||
			signature == "" {
			return nil, fmt.Errorf("shop item has incomplete presentation")
		}

		items = append(items, ShopItemView{
			ID:        uint64(id),
			Name:      name,
			Class:     class,
			Letter:    letter,
			Quantity:  int(quantity),
			Price:     price,
			OnList:    onList,
			Signature: signature,
		})
	}

	return items, nil
}

// ShopAtPlayer reads the Lua economy model without changing durable state.
func (g *Game) ShopAtPlayer(sort string) (ShopView, error) {
	result, err := g.scripts.Policy("shop.view", map[string]any{
		"sort": sort,
	})

	if err != nil {
		return ShopView{}, err
	}

	// A screen query has no mutation authority, even if a mod policy queues one.
	g.scripts.DiscardPending()
	available, ok := result["available"].(bool)

	if !ok {
		return ShopView{}, fmt.Errorf("shop view omitted availability")
	}

	if !available {
		return ShopView{}, nil
	}

	id, err := shopInteger(result, "shop_id")

	if err != nil {
		return ShopView{}, err
	}

	if id == 0 {
		return ShopView{}, fmt.Errorf("shop view has invalid ID")
	}

	gold, err := shopInteger(result, "gold")

	if err != nil {
		return ShopView{}, err
	}

	items, err := shopItems(result["items"])

	if err != nil {
		return ShopView{}, err
	}

	name, named := result["name"].(string)
	mode, sorted := result["sort"].(string)

	if !named ||
		name == "" ||
		!sorted {
		return ShopView{}, fmt.Errorf("shop view has incomplete header")
	}

	return ShopView{
		Available: true,
		ID:        uint64(id),
		Name:      name,
		Gold:      gold,
		Sort:      mode,
		Items:     items,
	}, nil
}

// BuyShop applies one all-or-nothing Lua purchase without advancing AUT.
func (g *Game) BuyShop(shopID uint64, ids []uint64) (ShopPurchase, error) {
	return g.buyShop(shopID, ids, nil)
}

// BuyShopSelection rejects stock that changed after the player selected it.
func (g *Game) BuyShopSelection(
	shopID uint64,
	selection []ShopSelection,
) (ShopPurchase, error) {
	ids := make([]uint64, 0, len(selection))
	expected := make([]any, 0, len(selection))

	for _, item := range selection {
		ids = append(ids, item.ID)
		expected = append(expected, map[string]any{
			"id":        item.ID,
			"price":     item.Price,
			"quantity":  item.Quantity,
			"signature": item.Signature,
		})
	}

	return g.buyShop(shopID, ids, expected)
}

func (g *Game) buyShop(
	shopID uint64,
	ids []uint64,
	expected []any,
) (ShopPurchase, error) {
	stock := make([]any, len(ids))

	for index, id := range ids {
		stock[index] = id
	}

	g.turn.Events = nil

	input := map[string]any{
		"shop_id":   shopID,
		"stock_ids": stock,
	}

	if expected != nil {
		input["expected"] = expected
	}

	result, err := g.scripts.Policy("shop.purchase", input)

	if err != nil {
		g.scripts.DiscardPending()

		return ShopPurchase{}, err
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return ShopPurchase{}, err
	}

	spent, err := shopInteger(result, "spent")

	if err != nil {
		return ShopPurchase{}, err
	}

	acquired, err := shopIDs(result["acquired"], "acquired")

	if err != nil {
		return ShopPurchase{}, err
	}

	outside, err := shopIDs(result["outside"], "outside")

	if err != nil {
		return ShopPurchase{}, err
	}

	for _, event := range g.turn.Events {
		g.messages = append(g.messages, event.Text)
	}

	if err := g.refreshVisibility(); err != nil {
		return ShopPurchase{}, err
	}

	return ShopPurchase{
		Spent:    spent,
		Acquired: acquired,
		Outside:  outside,
	}, nil
}

// ToggleShopList changes a player's durable bookmark for a stock entity.
func (g *Game) ToggleShopList(shopID, stockID uint64) (bool, error) {
	result, err := g.scripts.Policy("shop.list_toggle", map[string]any{
		"shop_id":  shopID,
		"stock_id": stockID,
	})

	if err != nil {
		g.scripts.DiscardPending()

		return false, err
	}

	listed, ok := result["listed"].(bool)

	if !ok {
		g.scripts.DiscardPending()

		return false, fmt.Errorf("shopping list policy omitted result")
	}

	if err := g.scripts.ApplyPending(); err != nil {
		return false, err
	}

	return listed, nil
}
