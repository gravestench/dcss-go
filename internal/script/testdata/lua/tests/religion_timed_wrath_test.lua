-- Ordinary wrath is earned with credited XP, saved on worship, and considered
-- once per god-time firing. These tests use the same component and Lua owners
-- as a real turn, so they exercise the registration and field defaults too.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local retribution = require("policy.religion.wrath.retribution")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local timer = require("policy.religion.wrath.timer")
local sources = require("constants.religion_sources")
local worship = require("policy.religion.worship")

local test = {}

-- Create a real player record so the XP threshold can read the species
-- aptitude and the saved wrath fields come from the production schema.
local function player(ctx, penance)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Wrath test",
    })
    ctx:add(entity, component.PROGRESSION, {
        level = 1,
    })
    ctx:add(entity, component.RELIGION_WORSHIP, {
        penance = penance,
    })

    return entity
end

-- Explicit draws show which stream owns each random decision. The wrapper
-- delegates every state read and write to the actual ECS context.
local function draws(ctx, expected)
    local proxy = setmetatable({}, { __index = ctx })
    local used = 0

    function proxy:random(stream, bound)
        used = used + 1

        local draw = expected[used]

        harness.truthy(draw, "unexpected wrath random draw")
        harness.equal(stream, draw.stream)
        harness.equal(bound, draw.bound)

        return draw.value
    end

    function proxy:used()
        return used
    end

    return proxy
end

-- A former non-good god stays active, while Zin without a hated new patron
-- does not enter the ordinary wrath lottery despite positive penance.
local function active_roster(ctx)
    local entity = player(ctx, {
        [gods.TROG] = 8,
        [gods.ZIN] = 8,
        [gods.NEMELEX_XOBEH] = 8,
    })
    local active = retribution.active_gods(ctx, entity)

    harness.equal(#active, 2)
    harness.equal(active[1], gods.TROG)
    harness.equal(active[2], gods.NEMELEX_XOBEH)
end

-- Nemelex's source retribution forces a punishment draw. The catalog's
-- Wraith card leaves saved drain on the player; this checks real dispatch.
local function nemelex_punishment(ctx)
    local entity = player(ctx, {
        [gods.NEMELEX_XOBEH] = 8,
    })
    local rule = setmetatable({}, { __index = ctx })
    local first = true

    function rule:random(stream, bound)
        if first then
            first = false
            harness.equal(stream, streams.CARDS)
            harness.equal(bound, 20)

            -- Catalog IDs are sorted; this weight selects Wraith.
            return 10
        end

        return ctx:random(stream, bound)
    end

    ctx:add(entity, component.HEALTH, {
        current = 20,
        max = 20,
    })

    harness.truthy(retribution.invoke_god(rule, entity,
        gods.NEMELEX_XOBEH, { no_bonus = true }))

    local drain = ctx:get(entity, component.PLAYER_DRAIN)

    harness.truthy(drain, "Nemelex punishment did not drain the player")
    harness.truthy(drain.amount > 0)
end

-- The first credited XP crosses the source zero counter. Further awards
-- advance the same saved threshold without making a new event each turn.
local function xp_queue(ctx)
    local entity = player(ctx, {
        [gods.TROG] = 8,
    })
    local rule = draws(ctx, {
        { stream = streams.RELIGION, bound = 200, value = 0 },
    })

    timer.gain_experience(rule, entity, 1)

    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 1)
    harness.truthy(state.wrath_xp_remaining >= 0)
    harness.equal(rule:used(), 1)

    local remaining = state.wrath_xp_remaining

    timer.gain_experience(rule, entity, 0)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 1)
    harness.equal(state.wrath_xp_remaining, remaining)
end

-- One god-time firing can invoke one angry god. Sif's MP-drain branch is
-- observable without a map and proves the existing handler actually ran.
local function queued_event(ctx)
    local entity = player(ctx, {
        [gods.SIF_MUNA] = 8,
    })

    ctx:add(entity, component.MAGIC, {
        current = 10,
        max = 10,
    })

    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    state.wrath_count = 1
    ctx:set(entity, component.RELIGION_WORSHIP, state)

    local rule = draws(ctx, {
        { stream = streams.RELIGION, bound = 20, value = 0 },
        { stream = streams.RELIGION, bound = 1, value = 0 },
        { stream = streams.CARDS, bound = 10, value = 6 },
        { stream = streams.CARDS, bound = 5, value = 1 },
        { stream = streams.CARDS, bound = 3, value = 0 },
    })

    timer.god_time(rule, entity)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 0)
    harness.equal(state.penance[gods.SIF_MUNA], 7)
    harness.equal(ctx:get(entity, component.MAGIC).current, 0)
    harness.equal(rule:used(), 5)
end

-- A temporarily inactive roster spends one queued count at god time.
-- The source clears the rest when a penance reduction mollifies the last
-- active god, rather than whenever worship temporarily changes eligibility.
local function no_active_penance(ctx)
    local entity = player(ctx, {})
    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    state.wrath_count = 2
    state.wrath_xp_remaining = 4
    ctx:set(entity, component.RELIGION_WORSHIP, state)

    timer.god_time(ctx, entity)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 1)
    harness.equal(state.wrath_xp_remaining, 4)

    timer.clear_if_mollified(ctx, entity)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 0)
    harness.equal(state.wrath_xp_remaining, 0)
end

-- A Wrath card may name a god without any penance. Its free punishment
-- cannot mollify that god, so another god's waiting debt must survive.
local function unpaid_card_draw(ctx)
    local entity = player(ctx, {})

    ctx:add(entity, component.MAGIC, {
        current = 10,
        max = 10,
    })

    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    state.wrath_count = 2
    state.wrath_xp_remaining = 4
    ctx:set(entity, component.RELIGION_WORSHIP, state)

    local rule = draws(ctx, {
        { stream = streams.CARDS, bound = 10, value = 6 },
        { stream = streams.CARDS, bound = 5, value = 1 },
        { stream = streams.CARDS, bound = 3, value = 0 },
    })

    harness.truthy(retribution.invoke_god(rule, entity, gods.SIF_MUNA))

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 2)
    harness.equal(state.wrath_xp_remaining, 4)
end

-- A former good god may become angry only after a later conversion. Source
-- starts its XP timeout then, so the very next small award is not a wrath.
local function good_god_conversion(ctx)
    local entity = player(ctx, {
        [gods.ZIN] = 8,
    })

    worship.join(ctx, entity, gods.MAKHLEB, sources.ALTAR)

    local state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.truthy(state.wrath_xp_remaining > 0,
        "newly active Zin wrath has no starting XP timeout")

    timer.gain_experience(ctx, entity, 1)

    state = ctx:get(entity, component.RELIGION_WORSHIP)

    harness.equal(state.wrath_count, 0)
end

-- Run the owner cases through the standard Lua rules harness.
function test.run(ctx)
    active_roster(ctx)
    nemelex_punishment(ctx)
    xp_queue(ctx)
    queued_event(ctx)
    no_active_penance(ctx)
    unpaid_card_draw(ctx)
    good_god_conversion(ctx)
end

return test
