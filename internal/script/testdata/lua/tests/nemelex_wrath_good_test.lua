-- Good-god wrath tests use production components and the saved summon/status
-- owners. Unsupported source branches fail explicitly at their own draw.
local attitudes = require("constants.attitude")
local cheibriados = require("policy.religion.wrath.cheibriados")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local gods = require("constants.gods")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local shining_one = require("policy.religion.wrath.shining_one")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local zin = require("policy.religion.wrath.zin")

local test = {}

-- A proxy fixes only card draws; status duration rolls remain with their
-- production stream, and source bounds are checked at the call site.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing card draw")
        harness.truthy(value >= 0 and value < bound,
            "card draw exceeded source bound")

        return value
    end

    function owner:draws_used()
        return used
    end

    return owner
end

-- Real PLAYER and POSITION state lets the shared status and summon owners
-- validate source effects without a mock component schema.
local function player_at(ctx, x)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 10,
    })

    return player
end

-- Zin skips removal slots on an unmutated body, and recital paralysis
-- returns false so the caller suppresses bonus debilitation.
local function zin_paralysis(ctx)
    local player = player_at(ctx, 10)
    local owner = with_draws(ctx, { 0, 2, 0 })

    harness.falsy(zin.apply(owner, player))
    harness.equal(ctx:get(player,
        component.PLAYER_PARALYSIS).remaining_aut, 20)
    harness.equal(owner:draws_used(), 3)
end

-- Zin's inclusive deletion loop makes at least one attempt even when all
-- seven binomial trials fail, and removal writes the real mutation record.
local function zin_removes_good(ctx)
    local player = player_at(ctx, 15)
    local owner = with_draws(ctx, {
        0, 99, 99, 99, 99, 99, 99, 99,
    })

    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 1)

    harness.truthy(zin.apply(owner, player))
    harness.falsy(records.find(ctx, player, mutations.MUT_ROBUST))
    harness.equal(owner:draws_used(), 8)
end

-- A first-level punishment sends one permanent hostile angel through the
-- normal summon placement owner and retains its source god in saved state.
local function shining_host(ctx)
    local player = player_at(ctx, 20)
    local site = fixture.context(ctx, player)
    local owner = with_draws(site, { 0, 0, 0, 0 })

    harness.truthy(shining_one.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })
    local angel = summoned[#summoned]
    local state = ctx:get(angel, component.SUMMON)

    harness.equal(ctx:get(angel, component.ACTOR).kind_id,
        monsters.MONS_ANGEL)
    harness.equal(state.source_id, gods.SHINING_ONE)
    harness.equal(state.attitude, attitudes.HOSTILE)
    harness.equal(state.expires_aut, 0)
    harness.equal(owner:draws_used(), 4)
end

-- The Silence branch uses the saved player aura. The separate cleansing
-- flame test covers the source's area blast and collateral damage.
local function shining_status(ctx)
    local player = player_at(ctx, 30)
    local owner = with_draws(ctx, { 6 })

    harness.truthy(shining_one.apply(owner, player))
    harness.truthy(ctx:get(player,
        component.PLAYER_STATUS).silence_aut > 0)
    harness.equal(owner:draws_used(), 1)
end

-- Cheibriados cannot select a source severity before the shared tension
-- score is exposed; rejecting it avoids a fabricated random punishment.
local function cheibriados_gap()
    local ok, message = pcall(cheibriados.apply)

    harness.falsy(ok)
    harness.truthy(string.find(message, "tension-based", 1, true))
end

-- Every test mutates a distinct production actor, so status and summon
-- assertions remain local even though the Lua runner shares one world.
function test.run(ctx)
    zin_paralysis(ctx)
    zin_removes_good(ctx)
    shining_host(ctx)
    shining_status(ctx)
    cheibriados_gap()
end

return test
