-- Theory of operation: one path owns worship transitions for every god.
-- Leaving clears current devotion and records the old god's source penance;
-- joining restores that god's starting state, applies first-patron and
-- good-god transfer rules, then runs a named per-god behavior module.
-- The resolved catalog lets a layered mod add a god without editing this file.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local eligibility = require("policy.religion.eligibility")
local gods = require("constants.gods")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local signals = require("constants.religion_signals")
local sources = require("constants.religion_sources")
local streams = require("constants.rng_streams")
local wrath_timer = require("policy.religion.wrath.timer")

local worship = {}

-- Load behavior only when the winning definition names a module. Most gods
-- have no immediate join effect, so they need no empty handler file.
local function behavior(definition)
    if not definition.behavior_module then
        return nil
    end

    return require(definition.behavior_module)
end

-- A missing history key is zero, and every recorded god counts against the
-- Monk's one-time first-patron bonus even after renunciation.
local function first_patrons(state)
    for _, count in pairs(state.worshipped) do
        if count > 0 then
            return false
        end
    end

    return true
end

-- A voluntary exit from a good god can bridge piety into the next good
-- faith. Forced loss of devotion must erase that bridge, even if the former
-- god was good; source excommunication receives that distinction explicitly.
local function preserve_good_piety(state, definition, voluntary)
    if definition.good and voluntary then
        state.previous_good_god = state.god_id
        state.saved_good_piety = state.piety

        return
    end

    state.previous_good_god = gods.NO_GOD
    state.saved_good_piety = 0
end

-- Set godless state before invoking the old god's leave handler, matching
-- excommunication's ordering. Penance is durable for the later wrath owner.
local function leave(ctx, player, state, next_god, voluntary)
    local old_id = state.god_id

    if old_id == gods.NO_GOD then
        return state
    end

    local definition = catalog.get(categories.GODS, old_id)

    preserve_good_piety(state, definition, voluntary)

    if old_id == gods.IGNIS then
        state.min_ignis_piety = math.min(
            state.min_ignis_piety,
            state.piety)
    end

    state.penance[old_id] = definition.wrath_penance
    state.god_id = gods.NO_GOD
    state.piety = 0
    state.piety_hysteresis = 0
    state.gift_timeout = 0

    ctx:set(player, component.RELIGION_WORSHIP, state)

    local handler = behavior(definition)

    if handler and handler.leave then
        handler.leave(ctx, player, state, next_god)
    end

    require("policy.religion.gifts").leave(ctx, player, old_id)

    ctx:signal(signals.LEFT, {
        player = player,
        god_id = old_id,
        next_god = next_god,
    })

    return ctx:get(player, component.RELIGION_WORSHIP)
end

-- The first half of a conversion is the same operation as explicit
-- renunciation. A godless player has no state to lose and spends no rule RNG.
function worship.renounce(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("renouncing requires worship state")
    end

    if state.god_id == gods.NO_GOD then
        return false
    end

    leave(ctx, player, state, gods.NO_GOD, true)

    return true
end

-- Conduct and timed piety decay can expel a player without their consent.
-- They share all god-specific cleanup with renunciation, but never preserve
-- a good-god piety bridge that could reward the later conversion.
function worship.excommunicate(ctx, player)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("excommunication requires worship state")
    end

    if state.god_id == gods.NO_GOD then
        return false
    end

    leave(ctx, player, state, gods.NO_GOD, false)

    return true
end

-- Xom consumes two independent 40-sided draws. Ignis instead reads the
-- lowest piety it retained before leaving, so rejoining cannot refill it.
local function initial_state(ctx, state, god_id, definition)
    state.god_id = god_id
    state.piety = definition.starting_piety
    state.piety_hysteresis = 0
    state.gift_timeout = 0
    state.penance[god_id] = 0

    if god_id == gods.XOM then
        state.gift_timeout = ctx:random(streams.RELIGION, 40) +
            ctx:random(streams.RELIGION, 40)
    end

    if god_id == gods.IGNIS then
        if (state.worshipped[god_id] or 0) > 0 then
            state.piety = state.min_ignis_piety
        else
            state.min_ignis_piety = state.piety
        end
    else
        state.piety_max[god_id] = math.max(
            state.piety_max[god_id] or 0,
            state.piety)
    end
end

-- The default Monk gift is 35 piety; exceptional gods expose a named
-- method so no source-specific switch grows in this common owner.
local function monk_bonus(ctx, player, god_id, was_first, handler)
    if not was_first then
        return
    end

    local identity = ctx:get(player, component.PLAYER)

    if identity.job_id ~= jobs.JOB_MONK then
        return
    end

    if handler and handler.monk_bonus then
        handler.monk_bonus(ctx, player)
    else
        piety.gain(ctx, player, 35, 1, false)
    end
end

-- Transfer the source's half-above-one-star devotion between good gods.
-- Clear the bridge only after the new god has received its share.
local function good_transfer(ctx, player, definition)
    local state = ctx:get(player, component.RELIGION_WORSHIP)
    local previous = state.previous_good_god

    if definition.good and previous ~= gods.NO_GOD then
        local old_definition = catalog.get(categories.GODS, previous)

        if old_definition.good and state.saved_good_piety > 30 then
            piety.gain(ctx, player, state.saved_good_piety - 30, 2, false)
        end
    end

    state = ctx:get(player, component.RELIGION_WORSHIP)
    state.previous_good_god = gods.NO_GOD
    state.saved_good_piety = 0
    ctx:set(player, component.RELIGION_WORSHIP, state)
end

-- An ecumenical altar grants 20 ordinary piety after joining. Named god
-- modules own exceptional rewards such as Ru's ready sacrifice offer.
local function ecumenical_bonus(ctx, player, source, handler)
    if source ~= sources.ECUMENICAL then
        return
    end

    if handler and handler.ecumenical_bonus then
        handler.ecumenical_bonus(ctx, player)
    else
        piety.gain(ctx, player, 20, 1, false)
    end
end

-- Convert only to a registered eligible god. The ecumenical altar waives
-- Gozag's money check, as in god-prayer.cc, while retaining all permanent
-- species and mutation restrictions.
local function check_join(ctx, player, god_id, source)
    if source ~= sources.ALTAR and source ~= sources.ECUMENICAL then
        error("unknown worship source " .. tostring(source))
    end

    if god_id == gods.NO_GOD or god_id == gods.ECUMENICAL then
        error("cannot join temporary or absent god " .. tostring(god_id))
    end

    local definition = catalog.get(categories.GODS, god_id)
    local temporary = source ~= sources.ECUMENICAL or god_id ~= gods.GOZAG
    local refusal = eligibility.check(ctx, player, god_id, temporary)

    if refusal then
        error(refusal)
    end

    return definition
end

-- A successful join completes one leave and one enter in source order.
-- The caller owns prayer confirmation and turn timing; this rule changes
-- only the durable worship, wallet, and god-specific state.
function worship.join(ctx, player, god_id, source)
    local definition = check_join(ctx, player, god_id, source)
    local state = ctx:get(player, component.RELIGION_WORSHIP)

    if not state then
        error("joining requires worship state")
    end

    if state.god_id == god_id then
        return false
    end

    local was_first = first_patrons(state)
    local old_god = state.god_id

    if state.god_id ~= gods.NO_GOD then
        state = leave(ctx, player, state, god_id, true)
    end

    initial_state(ctx, state, god_id, definition)
    ctx:set(player, component.RELIGION_WORSHIP, state)

    ctx:signal(signals.JOINED, {
        player = player,
        god_id = god_id,
    })

    local handler = behavior(definition)

    if handler and handler.prepare then
        handler.prepare(ctx, player)
    end

    monk_bonus(ctx, player, god_id, was_first, handler)
    good_transfer(ctx, player, definition)

    if handler and handler.join then
        handler.join(ctx, player, ctx:get(player, component.RELIGION_WORSHIP),
            source)
    end

    ecumenical_bonus(ctx, player, source, handler)

    state = ctx:get(player, component.RELIGION_WORSHIP)
    state.worshipped[god_id] = math.min(100,
        (state.worshipped[god_id] or 0) + 1)
    ctx:set(player, component.RELIGION_WORSHIP, state)

    wrath_timer.good_god_conversion(ctx, player, old_god)

    return true
end

return worship
