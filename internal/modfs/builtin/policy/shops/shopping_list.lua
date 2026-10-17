local component = require("constants.component")

local shopping_list = {}

local function state(ctx, player)
    local value = ctx:get(player, component.SHOPPING_LIST)

    if not value then
        error("player has no shopping list")
    end

    return value
end

function shopping_list.contains(ctx, player, stock)
    local wanted = ctx:id(stock)

    for _, entity in ipairs(state(ctx, player).stock_ids) do
        if ctx:id(entity) == wanted then
            return true
        end
    end

    return false
end

function shopping_list.remove(ctx, player, stock)
    local value = state(ctx, player)
    local wanted = ctx:id(stock)
    local kept = {}

    for _, entity in ipairs(value.stock_ids) do
        if ctx:id(entity) ~= wanted then
            kept[#kept + 1] = entity
        end
    end

    value.stock_ids = kept
    ctx:set(player, component.SHOPPING_LIST, value)
end

function shopping_list.toggle(ctx, player, stock)
    if not ctx:has(stock, component.SHOP_STOCK) then
        error("shopping list requires live shop stock")
    end

    if shopping_list.contains(ctx, player, stock) then
        shopping_list.remove(ctx, player, stock)

        return false
    end

    local value = state(ctx, player)

    value.stock_ids[#value.stock_ids + 1] = stock
    ctx:set(player, component.SHOPPING_LIST, value)

    return true
end

function shopping_list.run(ctx, input)
    local shop = ctx:entity(input.shop_id)
    local stock = ctx:entity(input.stock_id)
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)
    local shop_state = shop and ctx:get(shop, component.SHOP)
    local owner = stock and ctx:get(stock, component.SHOP_STOCK)

    if not shop_state or not shop_state.open or not position or
        position.level_id ~= shop_state.level_id or
        position.x ~= shop_state.x or position.y ~= shop_state.y or
        not owner or owner.shop_id ~= ctx:id(shop) then
        error("shopping list requires current shop stock")
    end

    return { listed = shopping_list.toggle(ctx, player, stock) }
end

register.policy({
    id = "shop.list_toggle",
    run = shopping_list.run,
})

return shopping_list
