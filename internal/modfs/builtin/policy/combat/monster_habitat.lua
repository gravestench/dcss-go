local monsters = require("ids.monsters")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local flight = require("policy.combat.flight")

local habitat = {}

-- Source: mon-place.cc:monster_habitable_grid, _feat_compatible and
-- terrain.cc:feat_has_solid_floor. Callers handle actor occupancy separately.
function habitat.at(ctx, monster, level_id, x, y)
    local actor = ctx:get(monster, component.ACTOR)

    if not actor then
        return false
    end

    local feature = ctx:cell(level_id, x, y)

    if feature == terrain_ids.DNGN_MALIGN_GATEWAY then
        return actor.kind_id == monsters.MONS_ELDRITCH_TENTACLE or
            actor.kind_id == monsters.MONS_ELDRITCH_TENTACLE_SEGMENT
    end

    if not ctx:walkable(level_id, x, y) then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local kind = definition.habitat_id

    if feature == terrain_ids.DNGN_LAVA then
        return kind == "HT_LAVA" or kind == "HT_AMPHIBIOUS_LAVA" or
            flight.active(ctx, monster)
    end

    if feature == terrain_ids.DNGN_DEEP_WATER then
        return kind == "HT_WATER" or kind == "HT_AMPHIBIOUS" or
            flight.active(ctx, monster)
    end

    if kind == "HT_WATER" then
        return feature == terrain_ids.DNGN_SHALLOW_WATER or
            feature == terrain_ids.DNGN_TOXIC_BOG
    end

    if kind == "HT_LAVA" then
        return false
    end

    return true
end

return habitat
