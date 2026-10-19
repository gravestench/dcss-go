local streams = require("constants.rng_streams")
local classes = require("ids.object_classes")
local component = require("constants.component")
local ids = require("ids.items")
local properties = require("policy.item_generation.artefacts.property_roll")
local rules = require("policy.item_generation.artefacts.property_rules")
local source = require("policy.item_generation.source_roll")
local weapon_brand = require("policy.item_generation.artefacts.weapon_brand")
local kinds = require("constants.artefact_kinds")
local names = require("policy.item_generation.artefacts.names")

local random = {}

local stat_rings = {
    [ids.RING_STRENGTH] = true,
    [ids.RING_INTELLIGENCE] = true,
    [ids.RING_DEXTERITY] = true,
}

-- Example: biased_random(ctx, 5, 3) favours lower values when reducing a randart weapon's plus.
-- Test ascending values with source chances, returning zero if no trial succeeds.
local function biased_random(ctx, maximum, trials)
    -- Source: crawl-ref/source/random.cc.
    for value = 0, maximum - 1 do
        if source.chance(ctx, trials,
            trials + maximum - 1 - value) then
            return value
        end
    end

    return 0
end

-- Subtract three biased draws from the source base plus, then enforce a small floor.
local function weapon_plus(ctx)
    local plus = 12

    for _ = 1, 3 do
        plus = plus - biased_random(ctx, 7, 2)
    end

    return math.max(plus, ctx:random(streams.ITEM_GENERATION, 2))
end

-- Body and shield bases derive enchantment bounds from AC; a few bases cannot enchant.
local function armour_maximum(definition)
    if definition.id == ids.ARM_QUICKSILVER_DRAGON_ARMOUR or
        definition.id == ids.ARM_SCARF or
        definition.id == ids.ARM_ORB then
        return 0
    end

    if definition.slot == "body" or definition.id == ids.ARM_BARDING then
        return definition.armour.ac
    end

    if definition.slot == "shield" then
        return math.floor((definition.armour.ac - 3) / 2) + 3
    end

    return 2
end

-- Source armour pluses combine ordinary, bonus, and penalty draws before slot floors.
local function armour_plus(ctx, definition)
    -- Source: crawl-ref/source/makeitem.cc.
    local maximum = armour_maximum(definition)
    local plus = 0

    if not source.chance(ctx, 1, 5) then
        plus = ctx:random(streams.ITEM_GENERATION, maximum + 1)

        if source.chance(ctx, 1, 5) then
            plus = plus + math.floor(
                ctx:random(streams.ITEM_GENERATION, maximum + 6) / 2)
        end

        if source.chance(ctx, 1, 6) then
            plus = plus - ctx:random(streams.ITEM_GENERATION, maximum + 6)
        end
    end

    if definition.slot == "body" then
        plus = math.max(plus, ctx:random(streams.ITEM_GENERATION, 2))
    else
        plus = math.max(plus, source.between(ctx, -2, 1))
    end

    if maximum == 0 then
        return 0
    end

    return plus
end

-- Stat rings cap at six pluses; other plus-bearing jewellery caps at four.
local function jewellery_plus(definition)
    if not definition.jewellery or
        not definition.jewellery.pluses then
        return 0
    end

    return stat_rings[definition.id] and 6 or 4
end

-- Choose the class-specific plus rule before assigning randart properties.
local function base_plus(ctx, definition)
    if definition.class == classes.OBJ_WEAPONS then
        return weapon_plus(ctx)
    elseif definition.class == classes.OBJ_ARMOUR then
        return armour_plus(ctx, definition)
    end

    return jewellery_plus(definition)
end

-- Store rolled properties and a cosmetic name seed together on the randart item component.
function random.apply(ctx, definition, result, forced_brand)
    if definition.class ~= classes.OBJ_WEAPONS and
        definition.class ~= classes.OBJ_ARMOUR and
        definition.class ~= classes.OBJ_JEWELLERY then
        return false
    end

    if definition.class == classes.OBJ_WEAPONS and
        definition.id == ids.WPN_CLUB then
        return false
    end

    if definition.class == classes.OBJ_ARMOUR and
        (definition.id == ids.ARM_SCARF or
            definition.id == ids.ARM_ORB) then
        return false
    end

    -- Source: crawl-ref/source/items.cc:item_def::is_mundane.
    local mundane = definition.id == ids.WPN_GIANT_CLUB or
        definition.id == ids.WPN_GIANT_SPIKED_CLUB or
        definition.id == ids.ARM_ANIMAL_SKIN

    if mundane and not source.chance(ctx, 1, 5) then
        return false
    end

    local plus = base_plus(ctx, definition)

    for _ = 1, 500 do
        local brand = ""

        if definition.class == classes.OBJ_WEAPONS and
            forced_brand and forced_brand ~= "" then
            brand = forced_brand
        elseif definition.class == classes.OBJ_WEAPONS then
            brand = weapon_brand.roll(ctx, definition)
        elseif definition.class == classes.OBJ_ARMOUR then
            brand = forced_brand or ""
        end

        local rolled = properties.properties(ctx, definition, brand)

        if not rules.bad(definition, rolled, brand) then
            local label, appearance, seed = names.generate(ctx, definition)
            local known = {}

            for id in pairs(rolled) do
                known[id] = false
            end

            result.plus = plus
            result.ego = ""
            result.components[component.ITEM_ARTEFACT] = {
                kind = kinds.RANDOM,
                unique_id = "",
                seed = seed,
                name = label,
                appearance = appearance,
                brand = brand,
                properties = rolled,
                known = known,
                flags = {},
            }

            return true
        end
    end

    return false
end

return random
