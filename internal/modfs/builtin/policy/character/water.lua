-- Example: A flying player over deep water is above water but not immersed in it.
local catalog = require("policy.catalog")
local component = require("constants.component")
local habitats = require("constants.monster_habitats")
local size = require("constants.size")
local terrain = require("constants.terrain")

local water = {}

local watery_features = {
    [terrain.DNGN_SHALLOW_WATER] = true,
    [terrain.DNGN_DEEP_WATER] = true,
    [terrain.DNGN_OPEN_SEA] = true,
    [terrain.DNGN_TOXIC_BOG] = true,
    [terrain.DNGN_MANGROVE] = true,
}

-- Source: terrain.cc:feat_is_water. Being over water and being immersed in
-- it are different: flight avoids wading but not the merfolk water bonus.
function water.at(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return false
    end

    local feature = ctx:cell(position.level_id, position.x, position.y)

    return watery_features[feature] == true
end

-- Flight keeps a player over water without counting as immersed for wading penalties.
function water.immersed(ctx, player)
    local flight = require("policy.combat.flight")

    return water.at(ctx, player) and not flight.active(ctx, player)
end

-- Use transformed body size when checking whether water is traversable.
function water.can_swim(ctx, player)
    local forms = require("policy.magic.effects.forms.player")
    local choice = ctx:get(player, component.PLAYER)

    if not choice then
        error("swimming player has no character choice")
    end

    local species = catalog.get("species", choice.species_id)
    local form = forms.modifiers(ctx, player)

    if form.swim == "forbid" then
        return false
    end

    if form.swim == "enable" then
        return true
    end

    local body_size = form.size or species.size

    return species.habitat == habitats.WATER or
        species.habitat == habitats.AMPHIBIOUS or
        (size.rank[body_size] or 0) >= size.rank[size.GIANT]
end

return water
