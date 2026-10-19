-- Changed quote rejected before debit.

local harness = require("tests.harness")
local component = require("constants.component")
local item_ids = require("ids.items")
local shop_ids = require("ids.shops")
local materialize = require("policy.item_generation.materialize")

local test = {}

-- Stable stock order lets a multi-item quote identify both selected entries.
local function stock_item(ctx, shop, order)
    return materialize.create(ctx, {
        kind_id = item_ids.WPN_CLUB,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    }, {
        shop = shop,
        order = order,
    })
end

-- Run purchase and shopping-list operations on real ECS entities to verify
-- that quoted stock, gold transfer, and ownership remain synchronized.
function test.run(ctx)
    local purchase = require("policy.shops.purchase")
    local list = require("policy.shops.shopping_list")
    local pricing = require("policy.shops.pricing")
    local signature = require("policy.shops.stock_signature")
    local player = ctx:create()
    local shop = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })
    ctx:add(player, component.WALLET, {
        gold = 15,
        purchases = 0,
    })
    ctx:add(player, component.SHOPPING_LIST, {})
    ctx:add(player, component.ITEM_KNOWLEDGE, {})
    ctx:add(shop, component.SHOP, {
        kind_id = shop_ids.SHOP_WEAPON,
        level_id = 1,
        x = 2,
        y = 1,
        name = "Weapon Shoppe",
        greed = 10,
        open = true,
    })

    local first = stock_item(ctx, shop, 1)
    local second = stock_item(ctx, shop, 2)

    list.toggle(ctx, player, first)
    harness.equal(#ctx:get(player, component.SHOPPING_LIST).stock_ids,
        1, "shopping list records stock")

    -- An unaffordable basket is atomic: neither item nor gold changes.
    local okay = pcall(purchase.buy, ctx, player, shop,
        { first, second })

    harness.falsy(okay, "unaffordable selection rejected together")
    harness.equal(ctx:get(player, component.WALLET).gold, 15,
        "failed purchase kept gold")
    harness.truthy(ctx:has(first, component.SHOP_STOCK),
        "failed purchase kept first stock item")
    harness.truthy(ctx:has(second, component.SHOP_STOCK),
        "failed purchase kept second stock item")

    okay = pcall(purchase.buy, ctx, player, shop, { first }, {
        {
            id = ctx:id(first),
            price = 999,
            quantity = 1,
        },
    })

    harness.falsy(okay, "changed quote rejected before debit")
    harness.equal(ctx:get(player, component.WALLET).gold, 15,
        "changed quote kept wallet")

    -- Price equality is insufficient: a stock signature detects swapped
    -- item identity between quoting and buying.
    local original = ctx:get(first, component.ITEM)
    local original_signature = signature.of(ctx, first)
    local original_price = pricing.quote(ctx, shop, first)
    local changed = ctx:get(first, component.ITEM)

    changed.ego = "SPWPN_NORMAL"
    ctx:set(first, component.ITEM, changed)

    harness.equal(pricing.quote(ctx, shop, first), original_price,
        "changed item kept the same quote")

    okay = pcall(purchase.buy, ctx, player, shop, { first }, {
        {
            id = ctx:id(first),
            price = original_price,
            quantity = 1,
            signature = original_signature,
        },
    })

    harness.falsy(okay, "same-price changed item rejected")
    ctx:set(first, component.ITEM, original)

    ctx:add(first, component.RESERVED_BY, { owner = player })
    okay = pcall(purchase.buy, ctx, player, shop, { first })

    harness.falsy(okay, "reserved stock cannot be purchased")
    ctx:remove(first, component.RESERVED_BY)

    ctx:set(player, component.WALLET, {
        gold = 30,
        purchases = 0,
    })

    -- Successful purchase transfers both items and removes their list entry.
    local result = purchase.buy(ctx, player, shop,
        { first, second })

    harness.equal(result.spent, 20, "two source prices charged")
    harness.equal(ctx:get(player, component.WALLET).gold, 10,
        "wallet debited once")
    harness.equal(ctx:get(player, component.WALLET).purchases, 20,
        "purchase total saved")
    harness.falsy(ctx:has(first, component.SHOP_STOCK),
        "first item left stock")
    harness.truthy(ctx:has(first, component.CARRIED_BY),
        "same first item carried")
    harness.equal(#ctx:get(player, component.SHOPPING_LIST).stock_ids,
        0, "purchased item removed from list")

    okay = pcall(purchase.buy, ctx, player, shop, { first })
    harness.falsy(okay, "repeat purchase rejected")
    harness.equal(ctx:get(player, component.WALLET).gold, 10,
        "repeat purchase kept balance")
end

return test
