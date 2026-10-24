-- The late harmful gates are easy to starve accidentally: every earlier
-- chance must fail in source order before clouds or banishment are tried.
local bad = require("policy.religion.xom.selection_bad")
local component = require("constants.component")
local events = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Use the production player, progress, and worship schemas so the late
-- eligibility checks see the same fields as an ordinary Xom action.
local function owner_with_player(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.XOM,
        piety = 0,
        gift_timeout = 10,
    })

    return owner, player,
        ctx:get(player, component.RELIGION_WORSHIP)
end

-- The expected bounds describe the source gate order, with all early
-- chance draws failing and one chosen late draw returning zero.
local function fixed_draws(owner, bounds, values)
    local index = 0

    -- Reject a changed RNG boundary at the first mismatching gate.
    function owner:random(stream, bound)
        index = index + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[index])

        return values[index] or bound - 1
    end

    -- The caller checks that its selected event consumed the entire path.
    return function()
        return index
    end
end

-- A free player cell and positive tension make the late chaos cloud
-- eligible after the stat-loss family fails its own chance.
local function cloud_gate(owner, player, state)
    local bounds = {}

    for index = 1, 14 do
        bounds[index] = 100
    end

    bounds[11] = 20

    local used = fixed_draws(owner, bounds, {
        [14] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_CHAOS_CLOUD)
    harness.equal(used(), 14)
end

-- A seasoned worshipper can suffer a real banishment if the source's
-- early avert roll fails. Piety zero makes immediate reversal impossible.
local function banishment_gate(owner, player, state)
    local bounds = {}

    for index = 1, 15 do
        bounds[index] = 100
    end

    bounds[11] = 20
    bounds[16] = 10

    local used = fixed_draws(owner, bounds, {
        [15] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_BANISHMENT)
    harness.equal(used(), 16)
end

-- One late severity success splits into stat loss, drain, or torment in
-- source coinflip order. Each branch uses the ordinary player resistance.
local function misfortune_gates(owner, player, state)
    local bounds = {}

    for index = 1, 13 do
        bounds[index] = 100
    end

    bounds[11] = 20
    bounds[14] = 2

    local stat_used = fixed_draws(owner, bounds, {
        [13] = 0,
        [14] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_STATLOSS)
    harness.equal(stat_used(), 14)

    bounds[15] = 2

    local drain_used = fixed_draws(owner, bounds, {
        [13] = 0,
        [15] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_DRAINING)
    harness.equal(drain_used(), 15)

    local torment_used = fixed_draws(owner, bounds, {
        [13] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_TORMENT)
    harness.equal(torment_used(), 15)
end

-- A non-bored worshipper with enough piety may have Xom reverse the
-- banishment immediately, yielding the real pseudo-travel event ID.
local function pseudo_banishment_gate(owner, player, state)
    local bounds = {}

    for index = 1, 15 do
        bounds[index] = 100
    end

    bounds[11] = 20
    bounds[16] = 10
    bounds[17] = 1000
    state.piety = 200

    local used = fixed_draws(owner, bounds, {
        [15] = 0,
        [17] = 0,
    })

    harness.equal(bad.choose(owner, player, state, 100, 20,
        streams.RELIGION), events.BAD_PSEUDO_BANISHMENT)
    harness.equal(used(), 17)
end

-- Both late paths share the same effective character and grid proxy.
function test.run(ctx)
    local owner, player, state = owner_with_player(ctx)

    cloud_gate(owner, player, state)
    banishment_gate(owner, player, state)
    misfortune_gates(owner, player, state)
    pseudo_banishment_gate(owner, player, state)
end

return test
