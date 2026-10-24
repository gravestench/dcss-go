-- Theory of operation: Channel Magic grants a saved duration, then each
-- player action converts elapsed aut into 3–5 MP per ten aut. Sif departure
-- and penance clear the same component immediately, before another tick.
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local power = require("policy.magic.power")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")

local channel = {}
local AUT_PER_TURN = 10
local MAX_DURATION_AUT = 1000

-- Source random2avg(n,2) averages two n-sided draws. Invocations is
-- evaluated at scale two and divided by three before that roll.
local function duration_turns(ctx, player)
    local training = power.training(ctx, player,
        skills.SK_INVOCATIONS, 2)
    local bound = roll.random_divide(ctx, training, 3,
        streams.RELIGION)

    if bound <= 0 then
        return 4
    end

    return 4 + roll.average_two(ctx, streams.RELIGION, bound)
end

-- Repeated invocations extend rather than replace the existing channel,
-- with the source hundred-turn cap applied after addition.
function channel.start(ctx, player)
    local current = ctx:get(player, component.RELIGION_SIF_CHANNEL)
    local remaining = current and current.remaining_aut or 0
    local added = duration_turns(ctx, player) * AUT_PER_TURN
    local next_aut = math.min(MAX_DURATION_AUT, remaining + added)

    if current then
        current.remaining_aut = next_aut
        ctx:set(player, component.RELIGION_SIF_CHANNEL, current)
    else
        ctx:add(player, component.RELIGION_SIF_CHANNEL, {
            remaining_aut = next_aut,
        })
    end

    ctx:emit(channels.RELIGION, "You feel invigorated.")
end

-- An abandoned patron cannot continue feeding an old timed effect.
function channel.clear(ctx, player)
    if ctx:has(player, component.RELIGION_SIF_CHANNEL) then
        ctx:remove(player, component.RELIGION_SIF_CHANNEL)
    end
end

-- Source div_rand_round scales each 3–5 MP draw by the action delay.
-- Fractional recovery uses the religion stream so save continuation agrees.
local function restored_magic(ctx, elapsed_aut)
    local amount = 3 + ctx:random(streams.RELIGION, 3)
    local numerator = elapsed_aut * amount
    local whole = math.floor(numerator / AUT_PER_TURN)
    local remainder = numerator % AUT_PER_TURN

    if remainder > 0 and
        ctx:random(streams.RELIGION, AUT_PER_TURN) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Duration ages even at full MP; otherwise a capped pool would preserve
-- channel forever. The current action also receives one recovery draw.
function channel.tick(ctx, player, elapsed_aut)
    local state = ctx:get(player, component.RELIGION_SIF_CHANNEL)

    if not state then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.SIF_MUNA or
        (worship.penance[gods.SIF_MUNA] or 0) > 0 then
        channel.clear(ctx, player)

        return
    end

    local magic = ctx:get(player, component.MAGIC)
    local restored = restored_magic(ctx, elapsed_aut)

    magic.current = math.min(magic.max, magic.current + restored)
    ctx:set(player, component.MAGIC, magic)

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        channel.clear(ctx, player)
        ctx:emit(channels.DURATION, "You feel less invigorated.")
    else
        ctx:set(player, component.RELIGION_SIF_CHANNEL, state)
    end
end

-- Save checks reject a timer that could never result from an invocation.
function channel.validate(ctx, player)
    local state = ctx:get(player, component.RELIGION_SIF_CHANNEL)

    if not state then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if state.remaining_aut <= 0 or
        state.remaining_aut > MAX_DURATION_AUT or
        not worship or worship.god_id ~= gods.SIF_MUNA or
        (worship.penance[gods.SIF_MUNA] or 0) > 0 then
        error("invalid Sif Muna channel state")
    end
end

return channel
