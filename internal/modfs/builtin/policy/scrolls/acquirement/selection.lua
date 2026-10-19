local catalog = require("policy.catalog")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local fighter = require("policy.combat.fighter")
local source = require("policy.item_generation.source_roll")

local selection = {}

-- Acquirement candidates are filtered by species, wearability, and prior sightings before weighting.
-- Use effective skill levels so subtype weights reflect training and mutation effects.
function selection.skill(ctx, skill_id)
    return fighter.skill_level(ctx, skill_id)
end

-- Example: a previously seen armour subtype can be deprioritized by offer generation.
-- Treat both identified and merely seen item types as familiar when penalizing repeat offers.
function selection.seen(ctx, player, kind_id)
    local knowledge = ctx:get(player, component.ITEM_KNOWLEDGE)

    if knowledge and (knowledge.known_types[kind_id] or
        knowledge.seen_types and knowledge.seen_types[kind_id]) then
        return true
    end

    for _, entity in ipairs(ctx:query({ component.ITEM, component.CARRIED_BY })) do
        local item = ctx:get(entity, component.ITEM)
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == player and item.kind_id == kind_id then
            return true
        end
    end

    return false
end

-- Read the saved species ID for wearability and aptitude decisions on the current player.
function selection.species(ctx, player)
    local choice = ctx:get(player, component.PLAYER)

    return catalog.get("species", choice.species_id)
end

-- Delegate species and equipment restrictions to the shared wearability rule.
function selection.wearable(ctx, player, species, definition)
    return equipment.can_wear(ctx, player, species, definition)
end

-- Reject an empty weighted pool before drawing, since callers have already filtered candidates.
function selection.weighted(ctx, rows)
    if #rows == 0 then
        error("acquirement has no eligible subtypes")
    end

    return source.weighted_id(ctx, rows)
end

return selection
