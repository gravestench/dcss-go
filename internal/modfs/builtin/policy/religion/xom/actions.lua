-- Xom owns one action path for ordinary worship and divine retribution.
-- Selection, live effects, renewed interest, and mood announcements stay
-- together so a card cannot silently use different Xom mechanics.
local capabilities = require("constants.jewellery_capabilities")
local accidental_death = require("policy.religion.xom.accidental_death")
local channels = require("constants.message_channels")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local gods = require("constants.gods")
local jewellery = require("policy.inventory.jewellery_effects")
local limits = require("constants.piety")
local mood = require("policy.religion.xom.mood")
local selection = require("policy.religion.xom.selection")
local sides = require("constants.xom_sides")
local streams = require("constants.rng_streams")
local tension = require("policy.combat.monster_seal_tension")

local actions = {}
local midpoint = math.floor(limits.MAX / 2)

-- Source x_chance_in_y spends no draw for impossible or certain results.
local function chance(ctx, stream, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(stream, denominator) < numerator
end

-- Xom becomes more likely to help under tension while he is interested.
-- Former worshippers receive the source card coinflip; penance is never
-- nice, regardless of the current piety number.
local function nice(ctx, player, state, local_tension, stream)
    if ((state.penance or {})[gods.XOM] or 0) > 0 then
        return false
    end

    if state.god_id ~= gods.XOM then
        return ctx:random(stream, 2) == 0
    end

    if state.gift_timeout < 1 then
        return false
    end

    local bonus = 0

    if local_tension > 0 then
        bonus = math.min(
            math.floor((limits.MAX - state.piety) / 2),
            ctx:random(stream, local_tension))
    end

    return chance(ctx, stream, state.piety + bonus, limits.MAX)
end

-- Source div_rand_round only draws when badness is fractional. A modded
-- event keeps its own effective badness metadata in the content catalog.
local function rounded_badness(ctx, definition, player, stream)
    if definition.dynamic_badness == "terrain" then
        return tension.current(ctx, player) > 0 and 3 or 1
    end

    local scaled = definition.badness_10x

    if type(scaled) ~= "number" or scaled < 0 then
        error("Xom bad event lacks valid badness")
    end

    local whole = math.floor(scaled / 10)
    local remainder = scaled % 10

    if remainder > 0 and ctx:random(stream, 10) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Xom's two-roll average renews boredom for a harmful act. The second
-- draw has one extra endpoint, matching random2avg rather than two
-- independent calls with the same bound.
local function renewed_interest(ctx, badness, stream)
    local bound = badness * 60

    if bound <= 0 then
        return 0
    end

    local first = ctx:random(stream, bound)
    local second = ctx:random(stream, bound + 1)

    return math.min(255, math.floor((first + second) / 2))
end

-- Apply a selected effect before updating Xom's saved attention and mood.
-- Both ordinary turns and retribution call this exact owner.
function actions.take(ctx, player, event_id, severity, stream)
    stream = stream or streams.RELIGION

    local definition = events.get(event_id)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local was_bored = state.god_id == gods.XOM and
        state.gift_timeout < 1
    local previous = mood.describe(state)
    local before = accidental_death.capture(ctx, player, state)

    events.apply(ctx, player, event_id, severity, {
        stream = stream,
    })

    state = ctx:get(player, component.RELIGION_WORSHIP)

    if definition.side == sides.BAD and
        state.god_id == gods.XOM and
        state.gift_timeout < 1 then
        local badness = rounded_badness(ctx, definition, player, stream)

        state.gift_timeout = renewed_interest(ctx, badness, stream)
        ctx:set(player, component.RELIGION_WORSHIP, state)
    end

    accidental_death.resolve(ctx, player, before)

    if state.god_id == gods.XOM and
        ctx:random(stream, 5) == 0 then
        state.piety = ctx:random(stream, limits.MAX + 1)
        ctx:set(player, component.RELIGION_WORSHIP, state)

        local current = mood.describe(state)

        if was_bored or previous ~= current then
            ctx:emit(channels.RELIGION,
                "You are now " .. current)
        end
    elseif was_bored then
        ctx:emit(channels.RELIGION,
            "You are now " .. mood.describe(state))
    end

    return event_id
end

-- An act derives severity from mood unless its caller supplies one.
-- Retaliation fixes niceness first; ordinary worship lets Xom decide.
function actions.act(ctx, player, request)
    request = request or {}

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        return nil
    end

    local stream = request.stream or streams.RELIGION
    local local_tension = request.tension

    if local_tension == nil or local_tension < 0 then
        local_tension = tension.current(ctx, player)
    end

    local severity = request.severity or
        math.abs(state.piety - midpoint)
    local niceness = request.nice

    if niceness == nil then
        niceness = nice(ctx, player, state,
            local_tension, stream)
    end

    local event_id = selection.choose(ctx, player, niceness,
        severity, local_tension, stream)

    if not event_id then
        return nil
    end

    return actions.take(ctx, player, event_id, severity, stream)
end

-- The source grades danger into five bands. Higher tension raises Xom's
-- ordinary action probability and occasionally revives bored interest.
local function danger_band(local_tension)
    if local_tension == 0 then
        return 1
    end

    if local_tension <= 5 then
        return 2
    end

    if local_tension <= 10 then
        return 3
    end

    if local_tension <= 20 then
        return 4
    end

    return 5
end

-- Called once after each completed player action. Mood drifts first;
-- only then can the current chance band produce a spontaneous Xom act.
function actions.tick(ctx, player, stream)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.god_id ~= gods.XOM then
        return nil
    end

    stream = stream or streams.RELIGION

    mood.drift(ctx, player, stream)
    state = ctx:get(player, component.RELIGION_WORSHIP)

    local faith = jewellery.has(ctx, player, capabilities.FAITH)
    local numerator = 2 + (faith and 1 or 0)

    if not chance(ctx, stream, numerator, 6) then
        return nil
    end

    local local_tension = tension.current(ctx, player)
    local band = danger_band(local_tension)
    local severity = math.abs(state.piety - midpoint)

    if state.gift_timeout < 1 and
        chance(ctx, stream, 25 - band * band, 100) then
        return actions.act(ctx, player, {
            severity = severity,
            tension = local_tension,
            stream = stream,
        })
    end

    if state.gift_timeout <= 1 and band > 1 and
        chance(ctx, stream, band - 1, 80) then
        local interest = ctx:random(stream, band * 15)

        if interest > 0 then
            state.gift_timeout = state.gift_timeout + interest
            ctx:set(player, component.RELIGION_WORSHIP, state)
            ctx:emit(channels.RELIGION,
                interest < 25 and "Xom is interested." or
                "Xom is intrigued.")
        end
    end

    if chance(ctx, stream, band * band, 100) then
        return actions.act(ctx, player, {
            severity = severity,
            tension = local_tension,
            stream = stream,
        })
    end

    return nil
end

return actions
