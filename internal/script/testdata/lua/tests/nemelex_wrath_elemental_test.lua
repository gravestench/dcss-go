-- Elemental wrath tests use actual saved summons and fixed card draw gates.
local component = require("constants.component")
local behaviors = require("constants.ai_behaviors")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ignis = require("policy.religion.wrath.ignis")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local qazlal = require("policy.religion.wrath.qazlal")
local species = require("ids.species")
local streams = require("constants.rng_streams")

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
        0, 1, 0,
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

-- A successful shaft stops before champion and summons; a separate
-- champion draw stops before elemental placement. Both write ECS state.
local function ignis_earlier_branches(ctx)
    local player = player_at(ctx, 40, 10)
    local shaft = with_draws(fixture.context(ctx, player), { 0, 0 })

    function shaft:level_depth(_)
        return 1
    end

    harness.truthy(ignis.apply(shaft, player))
    harness.truthy(ctx:has(player, component.PENDING_SHAFT))
    harness.equal(shaft:bounds()[1], 3)
    harness.equal(shaft:bounds()[2], 1)

    local other = player_at(ctx, 60, 10)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE, 62, 10)
    local champion = with_draws(fixture.context(ctx, other), { 1, 0 })

    ctx:add(ogre, component.AI, {
        behavior = behaviors.SLEEP,
    })

    harness.truthy(ignis.apply(champion, other))
    harness.truthy(ctx:has(ogre, component.IGNIS_FIRE_CHAMPION))
    harness.equal(champion:bounds()[1], 3)
    harness.equal(champion:bounds()[2], 2)
end

-- Exercise independent saved outcomes in source branch order so an earlier
-- summon cannot satisfy a later god attribution assertion.
function test.run(ctx)
    qazlal_servants(ctx)
    ignis_servants(ctx)
    ignis_earlier_branches(ctx)
end

return test
