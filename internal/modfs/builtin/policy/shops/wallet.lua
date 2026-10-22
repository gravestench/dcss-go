local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local classes = require("ids.object_classes")
local gods = require("constants.gods")
local limits = require("constants.wallet_limits")

local wallet = {}
local maximum = limits.MAX_EXACT

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

-- Source Gozag counts all accessible gold piles when a non-Abyss floor is
-- first populated. Use floor entities, not pickup history: an unseen pile
-- still contributes to the service fee. The population owner calls this
-- exactly once for each newly populated floor.
-- Example: wallet.record_level_gold(ctx, player, level_id) records 26 from
-- two floor piles of 17 and 9 without changing the carried balance.
function wallet.record_level_gold(ctx, player, level_id)
    local state = balance(ctx, player)
    local generated = 0

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.POSITION,
    })) do
        local floor = ctx:get(entity, component.POSITION)
        local item = ctx:get(entity, component.ITEM)

        if floor.level_id == level_id and
            catalog.get(categories.ITEMS, item.kind_id).class ==
                classes.OBJ_GOLD and
            not ctx:has(entity, component.CARRIED_BY) and
            not ctx:has(entity, component.SHOP_STOCK) then
            if not valid_amount(item.quantity) or item.quantity == 0 or
                generated > maximum - item.quantity then
                error("generated gold has invalid quantity")
            end

            generated = generated + item.quantity
        end
    end

    if state.generated_gold > maximum - generated then
        error("generated gold history would overflow")
    end

    state.generated_gold = state.generated_gold + generated
    ctx:set(player, component.WALLET, state)

    return generated
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

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if worship and worship.god_id ~= gods.NO_GOD then
        local definition = catalog.get(categories.GODS, worship.god_id)
        local handler = definition.behavior_module and
            require(definition.behavior_module)

        -- A god may own a gold transaction without adding a case to the
        -- common wallet. The named method receives the checked floor pile.
        if handler and handler.gold_pickup then
            local credited = handler.gold_pickup(ctx, player,
                gold_entity, item.quantity)

            ctx:destroy(gold_entity)

            return credited
        end
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
