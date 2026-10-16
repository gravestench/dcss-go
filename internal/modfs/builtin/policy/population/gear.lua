local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local items = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")
local registry = require("policy.population.gear.registry")

local gear = {}

function gear.draw(ctx, bound)
    return ctx:random("monster_gear", bound)
end

function gear.weighted(ctx, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        if choice.weight <= 0 or choice.id == "" then
            error("invalid weighted monster gear choice")
        end

        total = total + choice.weight
    end

    local choice = gear.draw(ctx, total)

    for _, row in ipairs(choices) do
        if choice < row.weight then
            return row.id == sentinels.NO_WEAPON and "" or row.id
        end

        choice = choice - row.weight
    end

    error("weighted monster gear failed to select")
end

local function nice_plusses(ctx, depth)
    local plus = 0

    -- The source alternates an increment and stop draw up to four times.
    for _ = 1, 4 do
        plus = plus + gear.draw(ctx, 3)

        if gear.draw(ctx, 425) > 35 + depth then
            break
        end
    end

    return plus
end

local function ordinary_brand(ctx, weights)
    local total = 0

    for _, row in ipairs(weights) do
        total = total + row.weight
    end

    if total == 0 then
        return brands.NORMAL
    end

    local choice = gear.draw(ctx, total)

    for _, row in ipairs(weights) do
        if choice < row.weight then
            return row.brand_id
        end

        choice = choice - row.weight
    end

    error("ordinary weapon brand table failed to select")
end

local supported_weapon = {}

for _, id in ipairs(require("data.early_weapons")) do
    supported_weapon[id] = true
end

function gear.quality(ctx, kind_id, depth)
    if not supported_weapon[kind_id] then
        error("unsupported ordinary weapon " .. tostring(kind_id))
    end

    local definition = catalog.get(categories.ITEMS, kind_id)

    if definition.class ~= classes.OBJ_WEAPONS or not definition.weapon then
        error("missing ordinary weapon properties " .. kind_id)
    end

    local quality_roll = gear.draw(ctx, 200)

    if quality_roll >= 51 + depth or kind_id == items.WPN_CLUB then
        return {
            plus = 0,
            ego = "",
        }
    end

    local brand_roll = gear.draw(ctx, 300)
    local brand = brands.NORMAL

    if brand_roll < 101 + depth then
        brand = ordinary_brand(ctx, definition.weapon.brand_weights or {})
    end

    local plus = nice_plusses(ctx, depth)

    if brand == brands.NORMAL and plus < 3 then
        plus = 0
    end

    return {
        plus = plus,
        ego = brand == brands.NORMAL and "" or brand,
    }
end

function gear.loadout(ctx, monster_id, depth)
    return registry.loadout(ctx, monster_id, depth)
end

gear.nice_plusses = nice_plusses

return gear
