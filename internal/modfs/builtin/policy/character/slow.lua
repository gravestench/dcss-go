-- Example: Haste stretches an incoming Slow timer using integer rounding.
local component = require("constants.component")
local time = require("constants.time")

local slow = {}

-- Lengthen Slow duration under Haste using source integer rounding.
local function haste_multiply(ctx, value)
    local numerator = value * 3
    local result = math.floor(numerator / 2)

    if numerator % 2 > 0 and ctx:random("speed", 2) == 0 then
        result = result + 1
    end

    return result
end

-- Only a positive saved timer changes the player action delay.
function slow.active(ctx, player)
    local state = ctx:get(player, component.PLAYER_SLOW)

    return state ~= nil and state.remaining_aut > 0
end

-- Source: player.cc:slow_player. Haste lengthens the duration because
-- slowed actions become shorter while haste is active.
function slow.apply(ctx, player, turns)
    if turns <= 0 then
        return false
    end

    local duration = ctx:get(player, component.DURATIONS)

    local hasted = duration and duration.haste_aut > 0

    if hasted then
        turns = haste_multiply(ctx, turns)
    end

    local added = turns * time.AUT_PER_TURN
    local maximum = (hasted and 150 or 100) * time.AUT_PER_TURN
    local state = ctx:get(player, component.PLAYER_SLOW)

    if state then
        state.remaining_aut = math.min(maximum,
            state.remaining_aut + added)
        ctx:set(player, component.PLAYER_SLOW, state)
    else
        ctx:add(player, component.PLAYER_SLOW, {
            remaining_aut = math.min(maximum, added),
        })
    end

    return true
end

-- Slow duration follows elapsed aut even when haste changes how many actions fit inside it.
function slow.tick(ctx, player, elapsed)
    local state = ctx:get(player, component.PLAYER_SLOW)

    if not state then
        return
    end

    local duration = ctx:get(player, component.DURATIONS)

    if duration and duration.haste_aut > 0 then
        elapsed = haste_multiply(ctx, elapsed)
    end

    state.remaining_aut = math.max(0, state.remaining_aut - elapsed)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.PLAYER_SLOW)
        ctx:emit("duration", "You feel yourself speed up.")
    else
        ctx:set(player, component.PLAYER_SLOW, state)
    end
end

return slow
