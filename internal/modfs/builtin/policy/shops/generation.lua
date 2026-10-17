local content = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local classes = require("ids.object_classes")
local ids = require("ids.shops")
local item_generation = require("policy.item_generation")
local identification = require("policy.shops.identification")
local quality = require("constants.vault_item_quality")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local generation = {}

local suffixes = { "Shoppe", "Boutique", "Emporium", "Shop" }
local no_suffix = {
    [ids.SHOP_GENERAL] = true,
    [ids.SHOP_GENERAL_ANTIQUE] = true,
    [ids.SHOP_DISTILLERY] = true,
}

local function positive_integer(value)
    return type(value) == "number" and value > 0 and value % 1 == 0
end

local function weighted(ctx, rows, key)
    local total = 0

    for _, row in ipairs(rows) do
        total = total + row.weight
    end

    if total <= 0 then
        error("shop selection has no positive weight")
    end

    local draw = ctx:random(streams.SHOP, total)

    for _, row in ipairs(rows) do
        if draw < row.weight then
            return row[key]
        end

        draw = draw - row.weight
    end

    error("shop selection fell outside weights")
end

local function shop_kind(ctx, selected)
    if selected and selected ~= ids.SHOP_RANDOM then
        return content.get(categories.SHOPS, selected)
    end

    local rows = {}

    for _, definition in ipairs(content.all(categories.SHOPS)) do
        rows[#rows + 1] = {
            id = definition.id,
            weight = definition.generation_weight,
        }
    end

    return content.get(categories.SHOPS, weighted(ctx, rows, "id"))
end

local function average(ctx, bound, count)
    local total = 0

    for _ = 1, count do
        total = total + ctx:random(streams.SHOP, bound)
    end

    return math.floor(total / count)
end

local function greed(ctx, definition, depth)
    if not definition.identifies_stock then
        return 15 + average(ctx, 19, 2) + ctx:random(streams.SHOP, depth)
    end

    return 10 + ctx:random(streams.SHOP, 5) +
        ctx:random(streams.SHOP, math.max(1, math.floor(depth / 2)))
end

local function item_depth(ctx, definition, depth)
    local multiplier = definition.identifies_stock and 2 or 3

    return depth + ctx:random(streams.SHOP, (depth + 1) * multiplier)
end

local function isolated_rng(ctx)
    local scoped = setmetatable({}, { __index = ctx })

    function scoped:random(_, bound)
        return ctx:random(streams.SHOP, bound)
    end

    return scoped
end

local function candidate(ctx, definition, spec, index, stocked)
    local request = {
        depth = item_depth(ctx, definition, spec.depth),
        quality = ctx:random(streams.SHOP, 4) == 0 and
            quality.GOOD or quality.ORDINARY,
        allow_uniques = false,
        site = "shop " .. definition.id,
    }

    if spec.items and #spec.items > 0 then
        local chosen = spec.use_all and spec.items[index] or
            spec.items[ctx:random(streams.SHOP, #spec.items) + 1]

        if chosen then
            request.kind_id = chosen
        end
    else
        local class_id = weighted(ctx, definition.class_weights, "class")

        if class_id ~= classes.OBJ_RANDOM then
            request.class_id = class_id
        end
    end

    local rolled = item_generation.roll(isolated_rng(ctx), request)
    local kind = content.get(categories.ITEMS, rolled.kind_id)

    if kind.class == classes.OBJ_GOLD then
        return nil
    end

    if definition.id == ids.SHOP_GENERAL_ANTIQUE and
        (not spec.items or #spec.items == 0) and
        (kind.class == classes.OBJ_MISSILES or
            kind.class == classes.OBJ_BOOKS) then
        return nil
    end

    if definition.id == ids.SHOP_BOOK then
        local copies = stocked[rolled.kind_id] or 0

        if ctx:random(streams.SHOP, copies + 1) ~= 0 then
            return nil
        end
    end

    return rolled
end

local function roll_stock(ctx, definition, spec, count)
    local results = {}
    local stocked = {}

    for index = 1, count do
        local result

        for _ = 1, 128 do
            result = candidate(ctx, definition, spec, index, stocked)

            if result then
                break
            end
        end

        if not result then
            error("shop " .. definition.id ..
                " cannot generate eligible stock in 128 attempts")
        end

        results[#results + 1] = result
        stocked[result.kind_id] = (stocked[result.kind_id] or 0) + 1
    end

    return results
end

local function shop_name(definition, spec)
    if spec.full_name and spec.full_name ~= "" then
        return spec.full_name
    end

    local type_name = spec.type_name or definition.name
    local owner = spec.name and spec.name ~= "" and spec.name .. "'s " or ""
    local suffix = spec.suffix

    if suffix == nil then
        suffix = no_suffix[definition.id] and "" or
            suffixes[(spec.x + spec.y) % #suffixes + 1]
    end

    return owner .. type_name .. (suffix ~= "" and " " .. suffix or "")
end

function generation.at(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.SHOP })) do
        local shop = ctx:get(entity, component.SHOP)

        if shop.level_id == level_id and shop.x == x and shop.y == y then
            return entity
        end
    end

    return nil
end

function generation.place(ctx, spec)
    if type(spec) ~= "table" or not positive_integer(spec.level_id) or
        not positive_integer(spec.depth) or
        type(spec.x) ~= "number" or spec.x % 1 ~= 0 or
        type(spec.y) ~= "number" or spec.y % 1 ~= 0 then
        error("shop placement requires level, cell, and depth")
    end

    if not ctx:walkable(spec.level_id, spec.x, spec.y) or
        ctx:cell(spec.level_id, spec.x, spec.y) ~= terrain.DNGN_FLOOR or
        generation.at(ctx, spec.level_id, spec.x, spec.y) then
        error("shop placement requires an unused floor cell")
    end

    local definition = shop_kind(ctx, spec.kind_id)
    local count = spec.count or
        (spec.use_all and spec.items and #spec.items) or
        5 + average(ctx, 8, 3)
    local shop_greed = spec.greed or greed(ctx, definition, spec.depth)

    if not positive_integer(count) or count > 64 or
        not positive_integer(shop_greed) then
        error("shop requires positive stock count and greed")
    end

    local stock = roll_stock(ctx, definition, spec, count)
    local keeper_a = ctx:random(streams.SHOP, 200) + 1
    local keeper_b = ctx:random(streams.SHOP, 200) + 1
    local shop = ctx:create()

    ctx:add(shop, component.SHOP, {
        kind_id = definition.id,
        level_id = spec.level_id,
        x = spec.x,
        y = spec.y,
        name = shop_name(definition, spec),
        greed = shop_greed,
        open = true,
        keeper_seed = keeper_a + keeper_b * 256 + keeper_b * 65536,
    })

    for order, result in ipairs(stock) do
        local entity = item_generation.create(ctx, result, {
            shop = shop,
            order = order,
        })

        if definition.identifies_stock then
            identification.stock(ctx, entity,
                content.get(categories.ITEMS, result.kind_id))
        end
    end

    ctx:set_cell(spec.level_id, spec.x, spec.y, terrain.DNGN_ENTER_SHOP)

    return shop
end

return generation
