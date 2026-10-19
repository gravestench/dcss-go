local catalog = require("policy.catalog")
local component = require("constants.component")
local classes = require("ids.object_classes")

local wallet = {}
local maximum = 9007199254740991

-- Require the saved wallet component for every transaction; silently
-- starting from zero would erase the player's recorded purchases.
local function balance(ctx, player)
    local state = ctx:get(player, component.WALLET)

    if not state then
        error("player has no wallet")
    end

    return state
end

-- Keep gold within Lua's exact-integer range so addition and price checks
-- cannot round an amount to a neighboring value.
local function valid_amount(value)
    return type(value) == "number" and
        value % 1 == 0 and value >= 0 and value <= maximum
end

-- Gold changes are made through one wallet component for both spending and pickup.
-- Example: wallet.can_spend(ctx, player, 50) checks carried gold before a purchase.
function wallet.can_spend(ctx, player, amount)
    return valid_amount(amount) and balance(ctx, player).gold >= amount
end

-- Debit gold and accumulate lifetime purchases together on the same saved
-- component, rejecting zero and overflow before mutating either field.
function wallet.spend(ctx, player, amount)
    local state = balance(ctx, player)

    if not valid_amount(amount) or amount == 0 or
        state.gold < amount or state.purchases > maximum - amount then
        error("insufficient gold or invalid purchase amount")
    end

    state.gold = state.gold - amount
    state.purchases = state.purchases + amount
    ctx:set(player, component.WALLET, state)
end

-- Accept only floor gold outside shop stock, then destroy its entity after
-- crediting the wallet so a repeated pickup cannot pay twice.
function wallet.pickup(ctx, player, gold_entity)
    local item = ctx:get(gold_entity, component.ITEM)
    local floor = ctx:get(gold_entity, component.POSITION)
    local state = balance(ctx, player)

    if not item or not floor or
        catalog.get("items", item.kind_id).class ~= classes.OBJ_GOLD or
        ctx:has(gold_entity, component.SHOP_STOCK) or
        not valid_amount(item.quantity) or item.quantity == 0 then
        error("gold pickup requires a floor gold item")
    end

    if state.gold > maximum - item.quantity then
        error("gold balance would overflow")
    end

    state.gold = state.gold + item.quantity
    ctx:set(player, component.WALLET, state)
    ctx:destroy(gold_entity)

    return item.quantity
end

return wallet
