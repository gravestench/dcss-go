-- Theory of operation: one saved player timer owns Trog's Hand. The
-- regeneration and willpower readers see the same live value, while a
-- small time system expires it before the next regeneration pass.
local component = require("constants.component")
local gods = require("constants.gods")
local streams = require("constants.rng_streams")

local hand = {}

-- Consumers check the timer rather than only the component's presence;
-- restore can briefly see a zeroed schema before the next status pass.
function hand.active(ctx, player)
    local state = ctx:get(player, component.RELIGION_TROG_HAND)

    return state ~= nil and state.remaining_aut > 0
end

-- Source rolls two piety-scaled dice, adds five turns, and extends the
-- current duration without exceeding one hundred turns total.
function hand.invoke(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local sides = math.floor(worship.piety / 6) + 1
    local turns = 5

    for _ = 1, 2 do
        turns = turns + 1 + ctx:random(streams.RELIGION, sides)
    end

    local state = ctx:get(player, component.RELIGION_TROG_HAND)

    if state then
        state.remaining_aut = math.min(1000,
            state.remaining_aut + turns * 10)
        ctx:set(player, component.RELIGION_TROG_HAND, state)
    else
        ctx:add(player, component.RELIGION_TROG_HAND, {
            remaining_aut = math.min(1000, turns * 10),
        })
    end

    ctx:emit("duration", "Your skin crawls.")
    ctx:emit("duration", "You feel strong-willed.")
end

-- Departure and penance cancel both effects immediately; the timed
-- expiry uses the same messages to avoid a silent willpower change.
function hand.clear(ctx, player)
    if not hand.active(ctx, player) then
        return false
    end

    ctx:remove(player, component.RELIGION_TROG_HAND)
    ctx:emit("duration", "Your skin stops crawling.")
    ctx:emit("duration", "You feel less strong-willed.")

    return true
end

-- Expiring duration warns at six turns and then drops both bonuses.
function hand.tick(ctx, player, aut)
    local state = ctx:get(player, component.RELIGION_TROG_HAND)

    if not state or aut <= 0 then
        return
    end

    local before = state.remaining_aut

    state.remaining_aut = math.max(0, before - aut)

    if before > 60 and state.remaining_aut <= 60 and
        state.remaining_aut > 0 then
        ctx:emit("duration", "You feel the effects of Trog's Hand fading.")
    end

    if state.remaining_aut == 0 then
        ctx:remove(player, component.RELIGION_TROG_HAND)
        ctx:emit("duration", "Your skin stops crawling.")
        ctx:emit("duration", "You feel less strong-willed.")
    else
        ctx:set(player, component.RELIGION_TROG_HAND, state)
    end
end

-- A saved Hand must belong to a living Trog worshipper and keep a bounded,
-- unexpired timer. Reject stale or forged effects before regeneration runs.
function hand.validate(ctx, player)
    for _, entity in ipairs(ctx:query({ component.RELIGION_TROG_HAND })) do
        if entity ~= player then
            error("Trog's Hand belongs only to the player")
        end

        local state = ctx:get(entity, component.RELIGION_TROG_HAND)
        local worship = ctx:get(player, component.RELIGION_WORSHIP)

        if state.remaining_aut < 1 or state.remaining_aut > 1000 or
            not worship or worship.god_id ~= gods.TROG or
            (worship.penance[gods.TROG] or 0) > 0 then
            error("invalid Trog's Hand state")
        end
    end
end

return hand
