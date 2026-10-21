-- The player's source Weak duration is capped at fifty turns and reduces
-- raw melee damage. Every change goes through one actor-owned component.
local component = require("constants.component")
local channels = require("constants.message_channels")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local weakness = {}

-- Source player::weaken adds power plus one bounded draw to the current
-- duration. Repeated gazes extend it but cannot exceed fifty turns.
-- Example: weakness.apply(ctx, player, 10) adds at least 100 aut.
function weakness.apply(ctx, player, power, stream)
    local current = ctx:get(player, component.PLAYER_WEAKNESS)
    local added = (power +
        ctx:random(stream or streams.MONSTER_SPELL, power + 3)) * 10
    local remaining = math.min(500,
        (current and current.remaining_aut or 0) + added)

    if current then
        ctx:set(player, component.PLAYER_WEAKNESS, {
            remaining_aut = remaining,
        })
        ctx:emit(channels.SPELL,
            "You feel as though you will be weak longer.")
    else
        ctx:add(player, component.PLAYER_WEAKNESS, {
            remaining_aut = remaining,
        })
        ctx:emit(channels.SPELL, "You feel your attacks grow feeble.")
    end
end

-- The raw player hit is reduced before armour; source stochastic
-- rounding keeps a weak one-point hit from always disappearing.
function weakness.melee_damage(ctx, player, raw)
    local current = ctx:get(player, component.PLAYER_WEAKNESS)

    if current and current.remaining_aut > 0 then
        return roll.random_divide(ctx, raw * 3, 4, streams.MELEE)
    end

    return raw
end

-- Action aut, not a fixed one-turn decrement, ages the saved status.
function weakness.tick(ctx, player, elapsed_aut)
    local current = ctx:get(player, component.PLAYER_WEAKNESS)

    if not current then
        return
    end

    current.remaining_aut = math.max(0,
        current.remaining_aut - elapsed_aut)

    if current.remaining_aut == 0 then
        ctx:remove(player, component.PLAYER_WEAKNESS)
        ctx:emit(channels.DURATION,
            "Your attacks feel stronger again.")
    else
        ctx:set(player, component.PLAYER_WEAKNESS, current)
    end
end

return weakness
