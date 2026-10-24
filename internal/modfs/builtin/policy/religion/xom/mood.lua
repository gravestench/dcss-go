-- Xom's piety is a mood, and gift timeout is interest. Neither follows
-- ordinary piety decay. Once per player action, his mood may drift toward
-- an extreme while his interest may decay toward boredom.
local capabilities = require("constants.jewellery_capabilities")
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local jewellery = require("policy.inventory.jewellery_effects")
local limits = require("constants.piety")
local piety = require("policy.religion.piety")
local streams = require("constants.rng_streams")

local mood = {}

local descriptions = {
    "a very special plaything of Xom.",
    "a special plaything of Xom.",
    "a plaything of Xom.",
    "a toy of Xom.",
    "a favourite toy of Xom.",
    "a beloved toy of Xom.",
    "Xom's teddy bear.",
}

local midpoint = math.floor(limits.MAX / 2)

-- The HUD and mood announcements use the same source phrase. A bored
-- worshipper's interest overrides the piety rank until Xom is amused again.
function mood.describe(state)
    if state.god_id ~= gods.XOM then
        return "a very buggy toy of Xom."
    end

    if state.gift_timeout < 1 then
        return "a BORING thing."
    end

    local rank = piety.rank(gods.XOM, state.piety)

    return descriptions[rank]
end

-- Source piety_scale gives Faith a one-in-four extra point on positive
-- deltas. Its signed integer division gives no extra point on minus one.
local function drift_delta(ctx, player, stream)
    local direction = ctx:random(stream, 1000) < 511 and 1 or -1

    if direction > 0 and
        jewellery.has(ctx, player, capabilities.FAITH) and
        ctx:random(stream, limits.FAITH_DIVISOR) == 0 then
        return 2
    end

    return direction
end

-- Moving across a description boundary takes an eightfold extra step.
-- That source nudge prevents favour text from oscillating each turn.
local function move_piety(state, good, size)
    state.piety = midpoint + (good and size or -size)
end

-- One in twenty player actions updates mood. Interest loses one point on
-- an independent coinflip during that same update, never on every aut.
function mood.drift(ctx, player, stream)
    stream = stream or streams.RELIGION

    if ctx:random(stream, 20) ~= 0 then
        return false
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id ~= gods.XOM then
        return false
    end

    local previous = mood.describe(state)
    local good = state.piety > midpoint

    if state.piety == midpoint then
        good = ctx:random(stream, 2) == 0
    end

    local size = math.abs(state.piety - midpoint)
    local delta = drift_delta(ctx, player, stream)

    size = math.min(midpoint, size + delta)
    move_piety(state, good, size)

    if mood.describe(state) ~= previous then
        size = math.min(midpoint, size + delta * 8)
        move_piety(state, good, size)
    end

    if state.gift_timeout > 0 and ctx:random(stream, 2) == 0 then
        state.gift_timeout = state.gift_timeout - 1
    end

    ctx:set(player, component.RELIGION_WORSHIP, state)

    local current = mood.describe(state)

    if current ~= previous then
        ctx:emit(channels.RELIGION, "You are now " .. current)
    end

    if state.gift_timeout == 1 then
        ctx:emit(channels.RELIGION, "Xom is getting BORED.")
    end

    return true
end

return mood
