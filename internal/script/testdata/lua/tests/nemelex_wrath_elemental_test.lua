-- Elemental wrath tests use actual saved summons and fixed card draw gates.
-- Unsupported source effects must stop at their own branch without fallback.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ignis = require("policy.religion.wrath.ignis")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local qazlal = require("policy.religion.wrath.qazlal")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local vehumet = require("policy.religion.wrath.vehumet")

local test = {}

-- Give each scenario a separate saved actor so summon assertions cannot
-- pass because an earlier branch left bodies in the shared test world.
local function player_at(ctx, x, level)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, x, 10)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = level,
    })

    return player
end

-- The prefix fixes branch gates; zero is valid for later placement draws.
-- Record every card bound so an error cannot silently spend later rolls.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = {}

    -- Fix only wrath's card stream; all other owner streams keep their
    -- production behavior while this records exact card call bounds.
    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used[#used + 1] = bound
        local value = draws[#used] or 0

        harness.truthy(value >= 0 and value < bound,
            "elemental wrath card draw exceeds source bound")

        return value
    end

    -- Expose the source draw sequence without copying a handler's choices.
    function owner:bounds()
        return used
    end

    return owner
end

-- XL7 avoids a rounding roll and requires two summon attempts; zero on
-- the weighted picker selects the first Qazlal elemental source row.
local function qazlal_servants(ctx)
    local player = player_at(ctx, 10, 7)
    local owner = with_draws(fixture.context(ctx, player), {
        1, 0, 0,
    })
    local before = #ctx:query({ component.SUMMON })

    harness.truthy(qazlal.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })
    local creature = summoned[#summoned]

    harness.equal(#summoned - before, 2)
    harness.equal(ctx:get(creature, component.ACTOR).kind_id,
        monsters.MONS_AIR_ELEMENTAL)
    harness.equal(ctx:get(creature, component.SUMMON).source_id,
        gods.QAZLAL)
    harness.equal(ctx:get(creature, component.SUMMON).expires_aut, 0)
    harness.equal(owner:bounds()[1], 2)
    harness.equal(owner:bounds()[2], 2)
end

-- The temporary mutation draw must fail at the branch gate because the
-- shared mutation owner cannot express the source god-gift protection.
local function qazlal_mutation_gap(ctx)
    local player = player_at(ctx, 20, 7)
    local owner = with_draws(fixture.context(ctx, player), { 1, 1 })
    local ok, message = pcall(qazlal.apply, owner, player)

    harness.falsy(ok)
    harness.truthy(string.find(message, "god-gift temporary mutation", 1,
        true))
    harness.equal(#owner:bounds(), 2)
end

-- Both fire elemental placements write permanent Ignis summons; a final
-- speech draw occurs only after at least one body arrives.
local function ignis_servants(ctx)
    local player = player_at(ctx, 30, 10)
    local owner = with_draws(fixture.context(ctx, player), {
        1, 1, 0,
    })
    local before = #ctx:query({ component.SUMMON })

    harness.truthy(ignis.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })
    local creature = summoned[#summoned]

    harness.equal(#summoned - before, 2)
    harness.equal(ctx:get(creature, component.ACTOR).kind_id,
        monsters.MONS_FIRE_ELEMENTAL)
    harness.equal(ctx:get(creature, component.SUMMON).source_id,
        gods.IGNIS)
    harness.equal(ctx:get(creature, component.SUMMON).expires_aut, 0)
    harness.equal(owner:bounds()[1], 3)
    harness.equal(owner:bounds()[2], 2)
    harness.equal(owner:bounds()[3], 2)
    harness.equal(owner:bounds()[#owner:bounds()], 70)
end

-- Reject shaft and champion draws before attempting any fallback summons;
-- each lacks a reusable source effect owner in the current Lua rules.
local function ignis_gaps(ctx)
    local player = player_at(ctx, 40, 10)
    local shaft = with_draws(fixture.context(ctx, player), { 0 })
    local ok, message = pcall(ignis.apply, shaft, player)

    harness.falsy(ok)
    harness.truthy(string.find(message, "shaft eligibility", 1, true))
    harness.equal(#shaft:bounds(), 1)

    local champion = with_draws(fixture.context(ctx, player), { 1, 0 })
    ok, message = pcall(ignis.apply, champion, player)

    harness.falsy(ok)
    harness.truthy(string.find(message, "fire champion", 1, true))
    harness.equal(#champion:bounds(), 2)
end

-- Avatar creation happens before Vehumet selects severity or a spell, so
-- the missing caster must fail before any card draw can be consumed.
local function vehumet_gap()
    local ok, message = pcall(vehumet.apply)

    harness.falsy(ok)
    harness.truthy(string.find(message, "god-avatar spell", 1, true))
end

-- Exercise independent saved outcomes in source branch order so an earlier
-- summon cannot satisfy a later god attribution assertion.
function test.run(ctx)
    qazlal_servants(ctx)
    qazlal_mutation_gap(ctx)
    ignis_servants(ctx)
    ignis_gaps(ctx)
    vehumet_gap()
end

return test
