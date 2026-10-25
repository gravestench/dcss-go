-- Theory of operation: one saved player clock runs source god-time checks.
-- The clock runs even without a god, so changing faith never resets the
-- schedule or consumes an extra random interval. At each firing the current
-- god definition decides whether ordinary piety may decay. A successful
-- one-point loss uses the normal hysteresis owner; zero piety expels the
-- player involuntarily through the same departure cleanup as renunciation.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local limits = require("constants.religion_upkeep")
local piety = require("policy.religion.piety")
local streams = require("constants.rng_streams")
local worship = require("policy.religion.worship")
local wrath_timer = require("policy.religion.wrath.timer")

local upkeep = {}

-- A newly created character starts with a 200-aut deadline. If an older
-- save has no clock, begin a fresh interval after its current elapsed time
-- rather than replaying missed checks all at once.
local function first_deadline(now)
    if now < limits.FIRST_AUT then
        return limits.FIRST_AUT
    end

    return now + limits.FIRST_AUT
end

-- The catalog field keeps a sparse mod god's maintenance rule with its own
-- definition. Nil means this god has another piety mechanic, such as Ru's
-- sacrifices or Uskayaw's combat momentum; it never means a default rate.
local function decay_check(ctx, player, state)
    if state.god_id == gods.NO_GOD then
        return state
    end

    local definition = catalog.get(categories.GODS, state.god_id)
    local chance = definition.piety_decay_chance

    if not chance then
        -- Ashenzari and Ru inspect zero piety at god time even though their
        -- normal devotion comes from curse and sacrifice offers. Other
        -- alternative gods return from the source timer before this check.
        if definition.god_time_zero_check and state.piety == 0 then
            worship.excommunicate(ctx, player)

            return ctx:get(player, component.RELIGION_WORSHIP)
        end

        return state
    end

    if ctx:random(streams.RELIGION, chance) == 0 then
        piety.lose(ctx, player, 1)
        state = ctx:get(player, component.RELIGION_WORSHIP)
    end

    -- Source handle_god_time checks for zero after the decay roll even when
    -- this check did not itself remove a point of piety.
    if state.piety == 0 then
        worship.excommunicate(ctx, player)
        state = ctx:get(player, component.RELIGION_WORSHIP)
    end

    return state
end

-- A god with its own clock action owns that behavior in a named Lua file.
-- Dispatch after decay so an expulsion cannot create a stale offer.
local function god_time_action(ctx, player, state)
    if state.god_id == gods.NO_GOD then
        return
    end

    local definition = catalog.get(categories.GODS, state.god_id)

    if definition.time_module then
        require(definition.time_module).at_god_time(ctx, player)
    end
end

-- Resolve every crossed deadline for a long action. The next deadline is
-- relative to the previous one, not the current action's end, so grouping
-- player aut into large or small actions cannot skip a god-time check.
function upkeep.tick(ctx, player, elapsed_aut)
    if type(elapsed_aut) ~= "number" or elapsed_aut % 1 ~= 0 or
        elapsed_aut < 0 then
        error("god time requires nonnegative integer elapsed aut")
    end

    if elapsed_aut == 0 then
        return
    end

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("god time requires player worship state")
    end

    local now = ctx:aut()

    if state.next_god_time_aut == 0 then
        state.next_god_time_aut = first_deadline(now)
    end

    local end_aut = now + elapsed_aut

    while state.next_god_time_aut <= end_aut do
        local due = state.next_god_time_aut

        wrath_timer.god_time(ctx, player)
        state = ctx:get(player, component.RELIGION_WORSHIP)
        state = decay_check(ctx, player, state)
        god_time_action(ctx, player, state)
        state.next_god_time_aut = due + limits.MIN_INTERVAL_AUT +
            ctx:random(streams.RELIGION, limits.INTERVAL_SPAN)
    end

    ctx:set(player, component.RELIGION_WORSHIP, state)
end

return upkeep
