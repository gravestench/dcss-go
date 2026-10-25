-- Theory of operation: credited XP accumulates a saved queue of possible
-- retributions from active penance. The first XP award crosses a zero timer;
-- later thresholds are 1/200 of the current XL span. God time spends one
-- queued count and samples an angry god through the existing effect owner.
-- The queue belongs to the player, so restoring a game cannot reroll debt.
local component = require("constants.component")
local experience_limit = require("policy.character.experience_limit")
local gods = require("constants.gods")
local alignments = require("constants.god_alignments")
local retribution = require("policy.religion.wrath.retribution")
local streams = require("constants.rng_streams")

local timer = {}
local good_wrath_order = {
    gods.ELYVILON,
    gods.SHINING_ONE,
    gods.ZIN,
}

-- Source div_rand_round draws only when a division has a remainder. Using
-- the religion stream keeps unrelated card and combat sequences stable.
local function rounded_share(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and
        ctx:random(streams.RELIGION, denominator) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Source set_penance_xp_timeout uses the next-level XP span at the current
-- XL and keeps negative overshoot, so one large award can queue many events.
local function threshold(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)

    if not progress then
        error("ordinary wrath requires player progression")
    end

    local span = experience_limit.needed(ctx, player,
        progress.level + 1) -
        experience_limit.needed(ctx, player, progress.level)

    return math.max(1, rounded_share(ctx, span, 200))
end

-- Source dec_penance clears earned debt only after a penance reduction
-- leaves no active god. An eligibility change by itself must not erase it.
function timer.clear_if_mollified(ctx, player)
    if #retribution.active_gods(ctx, player) > 0 then
        return false
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if state.wrath_count == 0 and state.wrath_xp_remaining == 0 then
        return true
    end

    state.wrath_count = 0
    state.wrath_xp_remaining = 0
    ctx:set(player, component.RELIGION_WORSHIP, state)

    return true
end

-- Source _inc_penance starts a positive XP interval for new conduct debt.
-- Renunciation uses a separate set-penance path and leaves this at zero,
-- making the first later credited XP queue an event immediately.
function timer.start_timeout(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state or state.wrath_xp_remaining > 0 then
        return
    end

    state.wrath_xp_remaining = state.wrath_xp_remaining +
        threshold(ctx, player)
    ctx:set(player, component.RELIGION_WORSHIP, state)
end

-- A good god left earlier may begin active wrath when a new patron is evil
-- or chaotic. Source conversion seeds the XP timeout at that moment and
-- excludes the god just left, whose renunciation did not seed a timer.
function timer.good_god_conversion(ctx, player, old_god)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local active = {}

    for _, god_id in ipairs(retribution.active_gods(ctx, player)) do
        active[god_id] = true
    end

    -- Preserve the source's warning order when several former good gods
    -- become angry at the same conversion; only the first seeds the timer.
    for _, god_id in ipairs(good_wrath_order) do
        if active[god_id] and god_id ~= old_god then
            timer.start_timeout(ctx, player)

            if god_id == gods.ZIN then
                local kind = alignments.CHAOTIC[state.god_id] and
                    "chaos" or "evil"

                ctx:emit("religion", "Zin says: You will suffer for " ..
                    "embracing such " .. kind .. "!")
            elseif god_id == gods.SHINING_ONE then
                ctx:emit("religion", "The Shining One says: You will " ..
                    "pay for your evil ways, mortal!")
            elseif god_id == gods.ELYVILON then
                ctx:emit("religion", "Elyvilon says: Your evil deeds " ..
                    "will not go unpunished!")
            end
        end
    end
end

-- Every credited XP award reaches this once through the common character
-- owner. No active penance means it consumes no wrath RNG.
function timer.gain_experience(ctx, player, amount)
    if type(amount) ~= "number" or amount < 0 or amount % 1 ~= 0 then
        error("ordinary wrath XP must be a nonnegative integer")
    end

    if amount == 0 or
        #retribution.active_gods(ctx, player) == 0 then
        return
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    state.wrath_xp_remaining = state.wrath_xp_remaining - amount

    while state.wrath_xp_remaining < 0 do
        state.wrath_count = state.wrath_count + 1
        state.wrath_xp_remaining = state.wrath_xp_remaining +
            threshold(ctx, player)
    end

    ctx:set(player, component.RELIGION_WORSHIP, state)
end

-- Source handle_god_time makes one chance test per queued event, then
-- consumes that event regardless of whether the draw caused punishment.
function timer.god_time(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("ordinary wrath requires player worship")
    end

    if state.wrath_count == 0 then
        return
    end

    local active = retribution.active_gods(ctx, player)
    local fires = #active > 0 and
        ctx:random(streams.RELIGION, 20) < #active

    -- Spend before the effect: a final penance payment can clear the whole
    -- queue during retribution, and saved counters must stay nonnegative.
    state.wrath_count = state.wrath_count - 1
    ctx:set(player, component.RELIGION_WORSHIP, state)

    if fires then
        local index = ctx:random(streams.RELIGION, #active) + 1

        retribution.invoke_god(ctx, player, active[index])
    end
end

return timer
