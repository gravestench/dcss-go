local harness = require("tests.harness")
local component = require("constants.component")
local item_ids = require("ids.items")
local materialize = require("policy.item_generation.materialize")

local test = {}

local function gold_at(ctx, quantity, x)
    return materialize.create(ctx, {
        kind_id = item_ids.OBJ_GOLD,
        quantity = quantity,
        plus = 0,
        charges = 0,
        ego = "",
    }, {
        position = {
            level_id = 1,
            x = x,
            y = 1,
        },
    })
end

function test.run(ctx)
    local wallet = require("policy.shops.wallet")
    local player = ctx:create()

    ctx:add(player, component.WALLET, {
        gold = 10,
        purchases = 0,
    })

    local floor_gold = gold_at(ctx, 17, 1)
    local deposited = wallet.pickup(ctx, player, floor_gold)

    harness.equal(deposited, 17, "deposited gold quantity")
    harness.equal(ctx:get(player, component.WALLET).gold, 27,
        "gold stored on player")
    harness.falsy(ctx:has(floor_gold, component.ITEM),
        "deposited floor gold removed")

    harness.falsy(wallet.can_spend(ctx, player, 28),
        "cannot spend more than balance")
    harness.truthy(wallet.can_spend(ctx, player, 27),
        "can spend exact balance")

    local okay = pcall(wallet.spend, ctx, player, 28)

    harness.falsy(okay, "overspend rejected")
    harness.equal(ctx:get(player, component.WALLET).gold, 27,
        "overspend kept balance")

    wallet.spend(ctx, player, 20)
    harness.equal(ctx:get(player, component.WALLET).gold, 7,
        "purchase debited balance")
    harness.equal(ctx:get(player, component.WALLET).purchases, 20,
        "purchase total recorded")

    ctx:set(player, component.WALLET, {
        gold = 9007199254740990,
        purchases = 20,
    })

    local overflowing = gold_at(ctx, 2, 2)
    okay = pcall(wallet.pickup, ctx, player, overflowing)

    harness.falsy(okay, "gold overflow rejected")
    harness.truthy(ctx:has(overflowing, component.ITEM),
        "overflow keeps floor gold")
    harness.equal(ctx:get(player, component.WALLET).gold,
        9007199254740990, "overflow keeps wallet")
end

return test
