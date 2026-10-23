-- Source god time is a saved 200-aut clock followed by 100–300 aut draws.
-- These tests use the production catalog and worship schema so adding a god
-- cannot silently inherit the wrong decay policy or lose its timer on save.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local streams = require("constants.rng_streams")
local upkeep = require("policy.religion.upkeep")
local worship = require("policy.religion.worship")
local piety = require("policy.religion.piety")

local test = {}

-- Keep a controllable clock around the real ECS methods. Every random draw
-- is asserted so a new rule cannot perturb the religion stream unnoticed.
local function clock(ctx, draws)
    local proxy = setmetatable({}, { __index = ctx })
    local now = 0
    local used = 0

    function proxy:aut()
        return now
    end

    function proxy:at(value)
        now = value
    end

    function proxy:random(stream, bound)
        used = used + 1

        local draw = draws[used]

        harness.equal(stream, streams.RELIGION)
        harness.truthy(draw, "unexpected religion timer draw")
        harness.equal(bound, draw.bound)

        return draw.value
    end

    function proxy:used()
        return used
    end

    return proxy
end

-- A worshipper is a real player component; each test receives an isolated
-- saved record and does not duplicate the worship schema in a fixture.
local function player(ctx, god_id, points)
    local entity = ctx:create()

    ctx:add(entity, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points,
    })

    return entity
end

-- First firing is at 200 aut. Hysteresis absorbs the first successful loss,
-- and the second loss decreases piety; the next deadline survives both.
local function ordinary_decay(ctx)
    local entity = player(ctx, gods.TROG, 30)
    local timed = clock(ctx, {
        { bound = 17, value = 0 },
        { bound = 201, value = 0 },
        { bound = 17, value = 0 },
        { bound = 201, value = 0 },
    })

    timed:at(190)
    upkeep.tick(timed, entity, 10)

    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 30)
    harness.equal(state.piety_hysteresis, 1)
    harness.equal(state.next_god_time_aut, 300)

    timed:at(200)
    upkeep.tick(timed, entity, 100)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 29)
    harness.equal(state.next_god_time_aut, 400)
    harness.equal(timed:used(), 4)
end

-- A source one-in-35 god shares the scheduler, while gods with alternative
-- piety mechanics consume no decay roll even when their timer fires.
local function god_rates(ctx)
    local rates = {
        [17] = 0,
        [35] = 0,
    }
    local alternatives = 0

    for _, id in ipairs(register.ids(categories.GODS)) do
        local chance = catalog.get(categories.GODS, id).piety_decay_chance

        if chance then
            harness.truthy(rates[chance] ~= nil,
                "source god has an expected maintenance rate")
            rates[chance] = rates[chance] + 1
        else
            alternatives = alternatives + 1
        end
    end

    harness.equal(rates[17], 13)
    harness.equal(rates[35], 6)
    harness.equal(alternatives, 7)

    local slow = player(ctx, gods.ELYVILON, 15)
    local timed = clock(ctx, {
        { bound = 35, value = 1 },
        { bound = 201, value = 200 },
    })

    upkeep.tick(timed, slow, 200)

    local state = ctx:get(slow, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 15)
    harness.equal(state.next_god_time_aut, 500)

    for _, god_id in ipairs({
        gods.ASHENZARI,
        gods.RU,
        gods.IGNIS,
        gods.USKAYAW,
        gods.YREDELEMNUL,
        gods.GOZAG,
        gods.XOM,
    }) do
        local entity = player(ctx, god_id, 15)
        local quiet = clock(ctx, {
            { bound = 201, value = 0 },
        })

        upkeep.tick(quiet, entity, 200)

        state = ctx:get(entity, component.RELIGION_WORSHIP)

        harness.equal(state.piety, 15)
        harness.equal(state.next_god_time_aut, 300)
        harness.equal(quiet:used(), 1)
    end

    -- Ru and Ashenzari do not roll ordinary decay, but source god time
    -- still expels either worshipper if another rule left piety at zero.
    for _, god_id in ipairs({ gods.RU, gods.ASHENZARI }) do
        local entity = player(ctx, god_id, 0)
        local quiet = clock(ctx, {
            { bound = 201, value = 0 },
        })

        upkeep.tick(quiet, entity, 200)

        harness.equal(ctx:get(entity, component.RELIGION_WORSHIP)
            .god_id, gods.NO_GOD)
        harness.equal(quiet:used(), 1)
    end
end

-- A conduct offense or timed piety loss is involuntary. It cannot carry
-- Zin's former piety into a later good god, while an explicit renunciation
-- may preserve that bridge under the source conversion rule.
local function involuntary_departure(ctx)
    local entity = player(ctx, gods.ZIN, 1)
    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    state.piety_hysteresis = 1
    ctx:set(entity, component.RELIGION_WORSHIP, state)

    local timed = clock(ctx, {
        { bound = 17, value = 0 },
        { bound = 201, value = 0 },
    })

    upkeep.tick(timed, entity, 200)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.god_id, gods.NO_GOD)
    harness.equal(state.previous_good_god, gods.NO_GOD)
    harness.equal(state.saved_good_piety, 0)
    harness.equal(state.next_god_time_aut, 300)
    harness.equal(state.penance[gods.ZIN],
        catalog.get(categories.GODS, gods.ZIN).wrath_penance)

    local offended = player(ctx, gods.ELYVILON, 1)

    piety.offend(ctx, offended, 3, 5)

    state = ctx:get(offended, component.RELIGION_WORSHIP)

    harness.equal(state.god_id, gods.NO_GOD)
    harness.equal(state.previous_good_god, gods.NO_GOD)
    harness.equal(state.saved_good_piety, 0)

    local volunteer = player(ctx, gods.ZIN, 90)

    worship.renounce(ctx, volunteer)

    state = ctx:get(volunteer, component.RELIGION_WORSHIP)

    harness.equal(state.previous_good_god, gods.ZIN)
    harness.equal(state.saved_good_piety, 90)
end

-- Execute the lifecycle through Lua's actual registration and ECS state.
function test.run(ctx)
    ordinary_decay(ctx)
    god_rates(ctx)
    involuntary_departure(ctx)
end

return test
