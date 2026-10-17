local categories = require("constants.catalog")
local component = require("constants.component")
local content = require("policy.catalog")
local classes = require("ids.object_classes")
local terrain = require("constants.terrain")

local shops = {}

local function cell_key(state)
    return string.format("%d:%d:%d", state.level_id, state.x, state.y)
end

local function valid_balance(value)
    return type(value) == "number" and value % 1 == 0 and
        value >= 0 and value <= 9007199254740991
end

local function validate_wallet(ctx)
    local player = ctx:player()
    local wallet = ctx:get(player, component.WALLET)
    local list = ctx:get(player, component.SHOPPING_LIST)

    if not wallet or not valid_balance(wallet.gold) or
        not valid_balance(wallet.purchases) then
        error("player has an invalid shop wallet")
    end

    if not list then
        error("player lacks a shopping list")
    end

    local seen = {}

    for _, stock in ipairs(list.stock_ids) do
        local id = ctx:id(stock)

        if seen[id] or not ctx:has(stock, component.SHOP_STOCK) then
            error("shopping list has an invalid shop stock reference")
        end

        seen[id] = true
    end
end

local function validate_shops(ctx)
    local occupied = {}

    for _, entity in ipairs(ctx:query({ component.SHOP })) do
        local state = ctx:get(entity, component.SHOP)
        local known = pcall(content.get, categories.SHOPS, state.kind_id)
        local key = cell_key(state)

        if not known or state.greed <= 0 or state.name == "" or
            not ctx:walkable(state.level_id, state.x, state.y) or
            ctx:cell(state.level_id, state.x, state.y) ~= terrain.DNGN_ENTER_SHOP or
            occupied[key] then
            error("shop " .. ctx:id(entity) .. " has invalid placement or kind")
        end

        occupied[key] = true
    end
end

local function validate_stock(ctx)
    local ordered = {}

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        local state = ctx:get(entity, component.SHOP_STOCK)
        local owner = ctx:entity(state.shop_id)
        local item = ctx:get(entity, component.ITEM)

        if not owner or not ctx:has(owner, component.SHOP) or
            not item or item.quantity <= 0 or
            content.get(categories.ITEMS, item.kind_id).class == classes.OBJ_GOLD or
            ctx:has(entity, component.POSITION) or
            ctx:has(entity, component.CARRIED_BY) or
            ctx:has(entity, component.RESERVED_BY) or
            state.order < 1 then
            error("shop stock " .. ctx:id(entity) .. " has invalid owner or location")
        end

        local key = tostring(state.shop_id) .. ":" .. tostring(state.order)

        if ordered[key] then
            error("duplicate shop stock order " .. key)
        end

        ordered[key] = true
    end
end

function shops.validate(ctx)
    validate_wallet(ctx)
    validate_shops(ctx)
    validate_stock(ctx)

    return {}
end

register.policy({
    id = "save.validate_shops",
    run = shops.validate,
})

return shops
