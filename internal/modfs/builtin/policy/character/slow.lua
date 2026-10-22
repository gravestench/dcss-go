-- Source slow_player stretches every incoming Slow timer because each
-- slowed action itself takes longer. Haste only changes timer decay.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local traits = require("policy.character.species_traits")
local time = require("constants.time")

local slow = {}

-- Round the source's three-halves duration and hasted decay independently.
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

-- Source: player.cc:slow_player. Stasis rejects all Slow sources before
-- timer writes; the three-halves conversion and cap apply even without Haste.
function slow.apply(ctx, player, turns)
    if turns <= 0 then
        return false
    end

    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local forms = require("policy.magic.effects.forms.player")

    if traits.stasis(species) or forms.stasis(ctx, player) then
        ctx:emit(channels.DURATION,
            "Your stasis prevents you from being slowed.")
        return false
    end

    local added = haste_multiply(ctx, turns) * time.AUT_PER_TURN
    local maximum = 150 * time.AUT_PER_TURN
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
