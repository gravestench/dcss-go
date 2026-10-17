local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local identification = require("policy.shops.identification")
local items = require("policy.inventory.items")
local pricing = require("policy.shops.pricing")
local shopping_list = require("policy.shops.shopping_list")
local stock_signature = require("policy.shops.stock_signature")
local wallet = require("policy.shops.wallet")

local purchase = {}
local maximum = 9007199254740991
local inventory_capacity = 52

local equipment = {
    [classes.OBJ_WEAPONS] = true,
    [classes.OBJ_ARMOUR] = true,
    [classes.OBJ_JEWELLERY] = true,
    [classes.OBJ_STAVES] = true,
}

local function stock_entity(ctx, value)
    if type(value) == "number" then
        return ctx:entity(value)
    end

    return value
end

local function at_shop(player_position, shop)
    return player_position and
        player_position.level_id == shop.level_id and
        player_position.x == shop.x and
        player_position.y == shop.y
end

local function carried_count(ctx, player)
    local count = 0

    for _, entity in ipairs(ctx:query({ component.ITEM, component.CARRIED_BY })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == player then
            count = count + 1
        end
    end

    return count
end

local function validate_selection(ctx, player, shop_entity, values, expected)
    local shop = ctx:get(shop_entity, component.SHOP)
    local position = ctx:get(player, component.POSITION)

    if not shop or not shop.open or not at_shop(position, shop) or
        type(values) ~= "table" or #values == 0 then
        error("purchase requires an open shop and selected stock")
    end

    if expected and (type(expected) ~= "table" or
        #expected ~= #values) then
        error("selected shop stock changed before confirmation")
    end

    local selected = {}
    local seen = {}
    local total = 0

    for _, value in ipairs(values) do
        local entity = stock_entity(ctx, value)
        local id = entity and ctx:id(entity) or 0
        local owner = entity and ctx:get(entity, component.SHOP_STOCK)
        local item = entity and ctx:get(entity, component.ITEM)

        if id == 0 or seen[id] or not owner or not item or
            owner.shop_id ~= ctx:id(shop_entity) or
            ctx:has(entity, component.POSITION) or
            ctx:has(entity, component.CARRIED_BY) or
            ctx:has(entity, component.RESERVED_BY) then
            error("selection contains stale or duplicate shop stock")
        end

        local kind = catalog.get("items", item.kind_id)

        if kind.class == classes.OBJ_GOLD then
            error("gold cannot be bought as shop stock")
        end

        local cost = pricing.quote(ctx, shop_entity, entity)

        if expected then
            local quote = expected[#selected + 1]

            if type(quote) ~= "table" or quote.id ~= id or
                quote.price ~= cost or quote.quantity ~= item.quantity or
                quote.signature ~= stock_signature.of(ctx, entity) then
                error("selected shop stock changed before confirmation")
            end
        end

        if cost > maximum - total then
            error("selected shop prices overflow")
        end

        seen[id] = true
        total = total + cost
        selected[#selected + 1] = {
            entity = entity,
            item = item,
            kind = kind,
        }
    end

    local balance = ctx:get(player, component.WALLET)

    if not wallet.can_spend(ctx, player, total) or
        balance.purchases > maximum - total then
        error("insufficient gold for selected shop stock")
    end

    return shop, selected, total
end

local function identify(ctx, player, entity, kind, shop_kind)
    if shop_kind.identifies_stock or equipment[kind.class] then
        identification.purchase(ctx, player, entity, kind)
    end
end

local function transfer(ctx, player, shop, selected, acquired, outside, count)
    local entity = selected.entity
    local item = selected.item
    local target = items.carried_stack(ctx, player, entity)

    shopping_list.remove(ctx, player, entity)
    ctx:remove(entity, component.SHOP_STOCK)

    if target then
        local stack = ctx:get(target, component.ITEM)

        stack.quantity = stack.quantity + item.quantity
        ctx:set(target, component.ITEM, stack)
        ctx:destroy(entity)
        acquired[#acquired + 1] = ctx:id(target)

        return count
    end

    if count >= inventory_capacity or selected.kind.stationary then
        ctx:add(entity, component.POSITION, {
            level_id = shop.level_id,
            x = shop.x,
            y = shop.y,
        })
        outside[#outside + 1] = ctx:id(entity)

        return count
    end

    ctx:add(entity, component.CARRIED_BY, { holder = player })
    acquired[#acquired + 1] = ctx:id(entity)

    return count + 1
end

function purchase.buy(ctx, player, shop_entity, stock_ids, expected)
    local shop, selected, total = validate_selection(ctx,
        player, shop_entity, stock_ids, expected)
    local shop_kind = catalog.get("shops", shop.kind_id)
    local acquired = {}
    local outside = {}
    local count = carried_count(ctx, player)

    wallet.spend(ctx, player, total)

    for _, entry in ipairs(selected) do
        identify(ctx, player, entry.entity, entry.kind, shop_kind)
        count = transfer(ctx, player, shop, entry,
            acquired, outside, count)
    end

    ctx:emit("shop", "Thank you for shopping!")

    return {
        spent = total,
        acquired = acquired,
        outside = outside,
    }
end

function purchase.run(ctx, input)
    local player = ctx:player()
    local shop = ctx:entity(input.shop_id)

    return purchase.buy(ctx, player, shop, input.stock_ids, input.expected)
end

register.policy({
    id = "shop.purchase",
    run = purchase.run,
})

return purchase
