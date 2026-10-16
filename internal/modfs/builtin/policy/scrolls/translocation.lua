-- Shared player movement checks from player.cc:no_tele_reason and
-- spl-transloc.cc:_find_cblink_target.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flight = require("policy.combat.flight")
local forms = require("policy.magic.effects.forms.player")
local terrain = require("constants.terrain")
local traits = require("policy.character.traits")
local water = require("policy.character.water")

local translocation = {}
local SIGHT_RADIUS = 7

function translocation.restriction(ctx, player)
    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    if traits.stasis(species) or forms.stasis(ctx, player) then
        return "Your stasis prevents you from teleporting."
    end

    return nil
end

function translocation.can_land(ctx, player, level_id, x, y)
    if not ctx:walkable(level_id, x, y) or
        ctx:actor_at(level_id, x, y) then
        return false
    end

    if flight.active(ctx, player) then
        return true
    end

    local feature = ctx:cell(level_id, x, y)

    return feature ~= terrain.DNGN_LAVA and
        (feature ~= terrain.DNGN_DEEP_WATER or
            water.can_swim(ctx, player))
end

function translocation.can_blink(ctx, player, origin, x, y)
    local distance = math.max(math.abs(x - origin.x),
        math.abs(y - origin.y))

    return distance > 0 and distance <= SIGHT_RADIUS and
        translocation.can_land(ctx, player, origin.level_id, x, y) and
        ctx:visible(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, x, y)
end

return translocation
