-- player.cc:acid_corrode and corrode_equipment.
local component = require("constants.component")
local channels = require("constants.message_channels")
local streams = require("constants.rng_streams")
local resistances = require("constants.resistance_ids")

local corrosion = {}

-- Example: corrosion.penalty(ctx, player) with expired corrosion -> 0 AC penalty
-- Expired corrosion contributes no AC or attack penalty even before its component is removed.
function corrosion.penalty(ctx, player)
    local state = ctx:get(player, component.CORROSION)

    if not state or state.remaining_aut < 1 then
        return 0
    end

    return 4 * state.stacks
end

-- Give acid three independent chances to corrode, increasing each chance with strength.
local function acid_hit(ctx, strength)
    local chance = strength + 1

    for _ = 1, 3 do
        if ctx:random(streams.CLOUDS, 30) < chance then
            return true
        end
    end

    return false
end

-- Direct corrosion, including Entropic Weave, skips the separate acid
-- splash chance. The equipment's rCorr protection still has its source
-- one-in-two opportunity to prevent this degree of corrosion.
function corrosion.corrode_equipment(ctx, player, source, stream,
    channel, degree)
    stream = stream or streams.CLOUDS
    degree = degree or 1

    if degree < 1 then
        return false
    end

    -- Damage imports fighter, which imports this policy for AC. Load it only
    -- when corrosion reaches a player to keep the module graph acyclic.
    local damage = require("policy.magic.damage")

    if damage.player_resistance(ctx, player, resistances.ACID) > 0 then
        local survived = 0

        -- Source binomial(degree, 50) protects each corrosion degree
        -- independently. A fully protected hit adds no duration.
        for _ = 1, degree do
            if ctx:random(stream, 2) == 1 then
                survived = survived + 1
            end
        end

        degree = survived

        if degree == 0 then
            return false
        end
    end

    local state = ctx:get(player, component.CORROSION) or {
        remaining_aut = 0,
        stacks = 0,
    }
    local duration = 10

    for _ = 1, 2 do
        duration = duration + 1 + ctx:random(stream, 4)
    end

    state.remaining_aut = math.min(500,
        state.remaining_aut + duration * 10)

    for _ = 1, degree do
        if ctx:random(stream, state.stacks + 7) >= state.stacks then
            state.stacks = state.stacks + 1
        end
    end

    if ctx:has(player, component.CORROSION) then
        ctx:set(player, component.CORROSION, state)
    else
        ctx:add(player, component.CORROSION, state)
    end

    ctx:emit(channel or channels.CLOUD,
        (source or "The acid") .. " corrodes you!")

    return true
end

-- Acid first needs an independent splash roll; a successful hit then uses
-- the same saved equipment-corrosion rule as direct monster spells.
function corrosion.apply(ctx, player, acid_strength)
    if not acid_hit(ctx, acid_strength) then
        return false
    end

    return corrosion.corrode_equipment(ctx, player,
        "The acid", streams.CLOUDS)
end

return corrosion
