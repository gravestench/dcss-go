-- player.cc:acid_corrode and corrode_equipment.
local component = require("constants.component")
local streams = require("constants.rng_streams")
local resistances = require("constants.resistance_ids")

local corrosion = {}

function corrosion.penalty(ctx, player)
    local state = ctx:get(player, component.CORROSION)

    if not state or state.remaining_aut < 1 then
        return 0
    end

    return 4 * state.stacks
end

local function acid_hit(ctx, strength)
    local chance = strength + 1

    for _ = 1, 3 do
        if ctx:random(streams.CLOUDS, 30) < chance then
            return true
        end
    end

    return false
end

function corrosion.apply(ctx, player, acid_strength)
    if not acid_hit(ctx, acid_strength) then
        return false
    end

    -- Damage imports fighter, which imports this policy for AC. Load it only
    -- when acid actually reaches a player to keep the module graph acyclic.
    local damage = require("policy.magic.damage")

    if damage.player_resistance(ctx, player, resistances.ACID) > 0 and
        ctx:random(streams.CLOUDS, 2) == 0 then
        return false
    end

    local state = ctx:get(player, component.CORROSION) or {
        remaining_aut = 0,
        stacks = 0,
    }
    local duration = 10

    for _ = 1, 2 do
        duration = duration + 1 + ctx:random(streams.CLOUDS, 4)
    end

    state.remaining_aut = math.min(500,
        state.remaining_aut + duration * 10)

    if ctx:random(streams.CLOUDS, state.stacks + 7) >= state.stacks then
        state.stacks = state.stacks + 1
    end

    if ctx:has(player, component.CORROSION) then
        ctx:set(player, component.CORROSION, state)
    else
        ctx:add(player, component.CORROSION, state)
    end

    ctx:emit("cloud", "The acid corrodes you!")

    return true
end

return corrosion
