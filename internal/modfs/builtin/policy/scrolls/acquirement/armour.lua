-- Source: crawl-ref/source/acquire.cc:_acquirement_armour_slot,
-- _acquirement_shield_type, and _body_acquirement_weight.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local ids = require("ids.items")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local armour = {}

local slots = {
    "body",
    "shield",
    "cloak",
    "head",
    "gloves",
    "boots",
}

-- Filter by generation mode and species wearability before a slot can enter the draw.
local function eligible(ctx, player, species, kind)
    return kind.class == classes.OBJ_ARMOUR and kind.armour and
        kind.generation.mode ~= "none" and
        selection.wearable(ctx, player, species, kind)
end

-- A slot enters the draw only if the current species can wear at least one generated kind in it.
local function slot(ctx, player, species)
    local rows = {}

    for _, slot_id in ipairs(slots) do
        local available = false

        for _, kind in ipairs(catalog.all("items")) do
            if kind.slot == slot_id and
                eligible(ctx, player, species, kind) then
                available = true
                break
            end
        end

        if available then
            rows[#rows + 1] = {
                id = slot_id,
                weight = 1,
            }
        end
    end

    return selection.weighted(ctx, rows)
end

-- Warrior rolls favour AC squared; non-warriors favour low EV burden as armour skill changes.
local function body_weight(ctx, kind, warrior)
    local base = kind.armour.acquire_weight or kind.generation.weight or 0

    if warrior then
        return base * kind.armour.ac * kind.armour.ac
    end

    local skill = math.min(27, selection.skill(ctx, skills.SK_ARMOUR) + 3)
    local difference = skill + math.floor(kind.armour.ev / 10)
    local inverse = math.max(1, 27 - difference)

    return base * inverse * inverse * inverse
end

-- Compare Armour training with Dodging and Spellcasting before preferring heavy protection.
local function warrior(ctx)
    local light = 3 * selection.skill(ctx, skills.SK_SPELLCASTING) +
        selection.skill(ctx, skills.SK_DODGING)
    local heavy = 2 * selection.skill(ctx, skills.SK_ARMOUR)

    if light <= 0 or heavy <= 0 then
        return light == 0 and heavy > 0
    end

    local light_roll = ctx:random(streams.ACQUIREMENT, light)
    local heavy_roll = ctx:random(streams.ACQUIREMENT, heavy)

    return light_roll < heavy_roll
end

-- Use slot-specific weights: body armour, shields, and secondary pieces have different source curves.
local function subtype_weight(ctx, kind, slot_id, warrior_pref)
    if slot_id == "body" then
        return body_weight(ctx, kind, warrior_pref)
    end

    if slot_id == "shield" then
        local shields = selection.skill(ctx, skills.SK_SHIELDS)

        if kind.id == ids.ARM_BUCKLER then
            return math.max(0, 20 - shields)
        elseif kind.id == ids.ARM_KITE_SHIELD then
            return 10
        elseif kind.id == ids.ARM_TOWER_SHIELD then
            return math.max(0, shields)
        end

        return kind.generation.weight or 0
    end

    if slot_id == "head" then
        if kind.id == ids.ARM_HELMET or kind.id == ids.ARM_HAT then
            return 1
        end
    elseif slot_id == "cloak" then
        if kind.id == ids.ARM_CLOAK or kind.id == ids.ARM_SCARF then
            return 1
        end
    elseif slot_id == "boots" then
        if kind.id == ids.ARM_BOOTS or kind.id == ids.ARM_BARDING then
            return 1
        end
    elseif slot_id == "gloves" then
        if kind.id == ids.ARM_GLOVES then
            return 1
        end
    end

    return kind.generation.weight or 0
end

-- Example: a species unable to wear body armour samples only its usable armour slots.
-- Choose a wearable slot before subtype weighting so body-size limits remain hard constraints.
function armour.pick(ctx, player)
    local species = selection.species(ctx, player)
    local slot_id = slot(ctx, player, species)
    local warrior_pref = slot_id == "body" and warrior(ctx)
    local rows = {}

    for _, kind in ipairs(catalog.all("items")) do
        if kind.slot == slot_id and eligible(ctx, player, species, kind) then
            local value = subtype_weight(ctx, kind, slot_id, warrior_pref)

            if value > 0 then
                rows[#rows + 1] = {
                    id = kind.id,
                    weight = value,
                }
            end
        end
    end

    return selection.weighted(ctx, rows)
end

return armour
