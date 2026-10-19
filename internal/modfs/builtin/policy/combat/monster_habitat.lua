local monsters = require("ids.monsters")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local flight = require("policy.combat.flight")
local flags = require("constants.monster_flags")
local habitats = require("constants.monster_habitats")

local habitat = {}

-- Example: habitat.at(ctx, monster, level_id, x, y) with monster over unsafe terrain -> false destination
-- Source: mon-place.cc:monster_habitable_grid, _feat_compatible and
-- terrain.cc:feat_has_solid_floor. Callers handle actor occupancy separately.
local function compatible(ctx, kind_id, definition, flying, level_id, x, y)
    local feature = ctx:cell(level_id, x, y)

    if feature == terrain_ids.DNGN_MALIGN_GATEWAY then
        return kind_id == monsters.MONS_ELDRITCH_TENTACLE or
            kind_id == monsters.MONS_ELDRITCH_TENTACLE_SEGMENT
    end

    if not ctx:walkable(level_id, x, y) then
        return false
    end

    local kind = definition.habitat_id

    if feature == terrain_ids.DNGN_LAVA then
        return kind == habitats.LAVA or
            kind == habitats.AMPHIBIOUS_LAVA or flying
    end

    if feature == terrain_ids.DNGN_DEEP_WATER then
        return kind == habitats.WATER or
            kind == habitats.AMPHIBIOUS or flying
    end

    if kind == habitats.WATER then
        return feature == terrain_ids.DNGN_SHALLOW_WATER or
            feature == terrain_ids.DNGN_TOXIC_BOG
    end

    if kind == habitats.LAVA then
        return false
    end

    return true
end

-- Existing actors may gain temporary flight, so inspect their live state.
function habitat.at(ctx, monster, level_id, x, y)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return compatible(ctx, actor.kind_id, definition,
        flight.active(ctx, monster), level_id, x, y)
end

-- A new summon has no entity or temporary status yet. Its catalog flight
-- flag and habitat still determine which cell may receive that actor.
function habitat.kind_at(ctx, kind_id, level_id, x, y)
    local definition = catalog.get("monsters", kind_id)
    local flying = false

    for _, flag in ipairs(definition.flags or {}) do
        flying = flying or flag == flags.FLIES
    end

    return compatible(ctx, kind_id, definition, flying,
        level_id, x, y)
end

return habitat
