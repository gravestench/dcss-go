-- Gozag's conversion fee depends on gold generated on floors, even when the
-- player never picks that gold up. The wallet keeps that historical amount.
local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local wallet = require("policy.shops.wallet")

local test = {}

-- Create a real floor item so accounting exercises production ECS fields.
local function floor_item(ctx, kind_id, quantity, level_id, stock)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = kind_id,
        quantity = quantity,
    })
    ctx:add(entity, component.POSITION, {
        level_id = level_id,
        x = 2,
        y = 3,
    })

    if stock then
        ctx:add(entity, component.SHOP_STOCK, {})
    end

    return entity
end

-- Count only accessible piles on the newly populated level. Picking up a
-- pile changes the balance, while its generated total stays historical.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.WALLET, {})
    floor_item(ctx, items.OBJ_GOLD, 17, 2)
    floor_item(ctx, items.OBJ_GOLD, 9, 2)
    floor_item(ctx, items.OBJ_GOLD, 4, 3)
    floor_item(ctx, items.POT_CURING, 1, 2)
    floor_item(ctx, items.OBJ_GOLD, 100, 2, true)

    wallet.record_level_gold(ctx, player, 2)

    local state = ctx:get(player, component.WALLET)

    harness.equal(state.generated_gold, 26)
    harness.equal(state.gold, 0)

    wallet.record_level_gold(ctx, player, 3)

    harness.equal(ctx:get(player, component.WALLET).generated_gold, 30)
end

return test
