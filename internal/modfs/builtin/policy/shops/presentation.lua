local catalog = require("policy.catalog")
local component = require("constants.component")
local identification = require("policy.items.identification")
local pricing = require("policy.shops.pricing")
local shopping_list = require("policy.shops.shopping_list")
local stock_signature = require("policy.shops.stock_signature")

local presentation = {}

local function stock_at(ctx, shop, player)
    local entries = {}

    for _, entity in ipairs(ctx:query({ component.SHOP_STOCK })) do
        local owner = ctx:get(entity, component.SHOP_STOCK)

        if owner.shop_id == ctx:id(shop) then
            local item = ctx:get(entity, component.ITEM)
            local kind = catalog.get("items", item.kind_id)

            entries[#entries + 1] = {
                id = ctx:id(entity),
                name = identification.name(ctx, player, entity),
                class = kind.class,
                class_order = kind.class_value,
                subtype_order = kind.subtype_value,
                quantity = item.quantity,
                order = owner.order,
                price = pricing.quote(ctx, shop, entity),
                on_list = shopping_list.contains(ctx, player, entity),
                signature = stock_signature.of(ctx, entity),
            }
        end
    end

    return entries
end

local function sort_price(left, right)
    if left.price ~= right.price then
        return left.price < right.price
    end

    return left.order < right.order
end

local function sort_name(left, right)
    if left.name ~= right.name then
        return left.name < right.name
    end

    return left.order < right.order
end

local function sort_type(left, right)
    if left.class_order ~= right.class_order then
        return left.class_order < right.class_order
    end

    if left.subtype_order ~= right.subtype_order then
        return left.subtype_order < right.subtype_order
    end

    return left.order < right.order
end

local function sorter(mode)
    if mode == "price" then
        return sort_price
    elseif mode == "name" then
        return sort_name
    end

    return sort_type
end

local function letter(index)
    if index <= 25 then
        local offset = index - 1

        if offset >= 23 then
            offset = offset + 1
        end

        return string.char(string.byte("a") + offset)
    elseif index <= 50 then
        local offset = index - 26

        if offset >= 23 then
            offset = offset + 1
        end

        return string.char(string.byte("A") + offset)
    end

    return ""
end

function presentation.view(ctx, input)
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)

    if not position then
        return { available = false }
    end

    local shop

    for _, entity in ipairs(ctx:query({ component.SHOP })) do
        local state = ctx:get(entity, component.SHOP)

        if state.level_id == position.level_id and
            state.x == position.x and state.y == position.y then
            shop = entity
            break
        end
    end

    if not shop then
        return { available = false }
    end

    local state = ctx:get(shop, component.SHOP)
    local wallet = ctx:get(player, component.WALLET)
    local items = stock_at(ctx, shop, player)
    local sort = input and input.sort or "type"

    table.sort(items, sorter(sort))

    for index, item in ipairs(items) do
        item.letter = letter(index)
    end

    return {
        available = true,
        shop_id = ctx:id(shop),
        name = state.name,
        gold = wallet.gold,
        sort = sort,
        items = items,
    }
end

register.policy({
    id = "shop.view",
    run = presentation.view,
})

return presentation
