local spells = require("ids.spells")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local catalog = require("policy.catalog")
local common = require("policy.magic.effects.translocation.common")
local registry = require("policy.magic.effects.registry")

local liquefaction = {}

-- A cell liquefies only within the active player's area and on the player's current level.
function liquefaction.at(ctx, level_id, x, y)
    local player = ctx:player()
    local state = ctx:get(player, component.LIQUEFACTION)

    if not state or state.remaining_aut <= 0 then
        return false
    end

    local origin = ctx:get(player, component.POSITION)

    if origin.level_id ~= level_id then
        return false
    end

    local turns = math.floor(state.remaining_aut / 10)
    local radius = math.floor(math.sqrt(math.max(0,
        math.min(math.floor(3 * (turns - 5) / 4), 25))))
    local feature = ctx:cell(level_id, x, y)

    return feature ~= terrain_ids.DNGN_LAVA and
        feature ~= terrain_ids.DNGN_SHALLOW_WATER and
        feature ~= terrain_ids.DNGN_DEEP_WATER and
        feature ~= terrain_ids.DNGN_OPEN_SEA and
        common.distance(origin, { x = x, y = y }) <= radius
end

-- Monsters in affected ground flounder while the player's liquefaction status persists.
function liquefaction.floundering(ctx, monster)
    local position = ctx:get(monster, component.POSITION)
    local actor = ctx:get(monster, component.ACTOR)

    if not position or not actor or
        not liquefaction.at(ctx, position.level_id,
            position.x, position.y) then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    return not common.flag(definition, "M_FLIES")
end

-- Example: An aura with ten aut remaining ends after a ten-aut tick and restores solid ground.
-- Decrement the shared aura in aut and announce once when its ground effect ends.
function liquefaction.tick(ctx, player, aut)
    local state = ctx:get(player, component.LIQUEFACTION)

    if not state or aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.LIQUEFACTION)
        ctx:emit("duration", "The ground around you solidifies again.")
    else
        ctx:set(player, component.LIQUEFACTION, state)
    end
end

-- Source: spl-selfench.cc:cast_liquefaction and areas.cc:liquefied.
function liquefaction.resolve(ctx, player, _, _, power)
    local bound = math.max(1, power)
    local rolled = ctx:random("spell", bound) +
        ctx:random("spell", bound)
    local turns = 10 + math.floor(rolled / 2)
    local state = ctx:get(player, component.LIQUEFACTION)
    local remaining = math.min(1000,
        (state and state.remaining_aut or 0) + turns * 10)

    if state then
        state.remaining_aut = remaining
        ctx:set(player, component.LIQUEFACTION, state)
    else
        ctx:add(player, component.LIQUEFACTION, {
            remaining_aut = remaining,
        })
    end

    ctx:emit("spell", "The ground around you becomes liquefied!")
end

registry.add(spells.SPELL_LEDAS_LIQUEFACTION, {
    resolve = liquefaction.resolve,
})

return liquefaction
