-- Example: A monster weapon plus roll uses the gear stream, leaving layout RNG unchanged.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local items = require("ids.items")
local brands = require("constants.weapon_brands")
local sentinels = require("constants.monster_gear_sentinels")
local registry = require("policy.population.gear.registry")
local streams = require("constants.rng_streams")
local unique_history = require("policy.item_generation.artefacts.history")

local gear = {}

-- Keep all monster equipment randomness on the dedicated gear stream.
function gear.draw(ctx, bound)
    return ctx:random(streams.MONSTER_GEAR, bound)
end

-- Source rolls a chance before asking whether a named artefact was already
-- generated. Preserve that draw even for a claimed item so later monster
-- gear decisions remain on the same saved stream.
function gear.chance_unique(ctx, unique_id, odds)
    local selected = gear.draw(ctx, odds) == 0

    return selected and
        unique_history.status(ctx, ctx:player(), unique_id) == nil
end

-- Use one gear-stream draw over source weights so table order stays meaningful.
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

-- Depth influences the range of weapon plusses before branding is considered.
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

-- Brand selection consumes its own weighted draw only when a quality roll reaches it.
local function ordinary_brand(ctx, weights)
    -- Content files use mod.null for an absent source brand table. It is a
    -- truthy userdata value in Lua, so normalize it before ipairs.
    if type(weights) ~= "table" then
        return brands.NORMAL
    end

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

-- Monster gear quality draws plusses and brand through the gear stream after kind selection.
function gear.quality(ctx, kind_id, depth)
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

-- Source weapon specs with unconditional plusses and a forced brand do
-- not pass through ordinary item generation. Use their imported range
-- and brand, including random2avg's larger later-roll bound.
local function forced_spec_quality(ctx, spec)
    local plus = spec.plus
    local choices = spec.brands

    if not plus or plus.odds ~= 1 or spec.good_chance ~= 0 or
        type(choices) ~= "table" or #choices ~= 1 or
        choices[1].id == sentinels.NO_FORCED_BRAND then
        return nil
    end

    local rolls = math.max(1, plus.rolls or 0)
    local span = plus.max - plus.min + 1
    local total = gear.draw(ctx, span)

    for _ = 2, rolls do
        total = total + gear.draw(ctx, span + 1)
    end

    return {
        plus = plus.min + math.floor(total / rolls),
        ego = gear.weighted(ctx, choices),
    }
end

-- Read the catalog weapon row independently so a named armour grant can
-- preserve its ordinary weapon draw. Other special handlers may still
-- replace this path when source gear has a distinct roll order.
function gear.ordinary_loadout(ctx, monster_id, depth)
    local definition = catalog.get(categories.MONSTERS, monster_id)
    local owned = definition.weapon_gear

    if not owned then
        return nil
    end

    local loadout = {}

    for _, slot in ipairs({ "primary", "secondary" }) do
        local spec = owned[slot]

        if spec then
            local kind_id = gear.weighted(ctx, spec.weapons)

            if kind_id ~= "" then
                local selected = {
                    kind_id = kind_id,
                    quality = forced_spec_quality(ctx, spec) or
                        gear.quality(ctx, kind_id, depth),
                }

                if slot == "primary" then
                    loadout.primary = selected
                else
                    loadout.alternate = selected
                end
            end
        end
    end

    if not loadout.primary and not loadout.alternate then
        return nil
    end

    if not loadout.primary then
        loadout.primary = loadout.alternate
        loadout.alternate = nil
    end

    return loadout
end

-- Species-specific handlers override the ordinary gear path without changing spawn order.
function gear.loadout(ctx, monster_id, depth)
    local special = registry.loadout(ctx, monster_id, depth)

    if special then
        return special
    end

    return gear.ordinary_loadout(ctx, monster_id, depth)
end

gear.nice_plusses = nice_plusses

return gear
