-- Source-selected nature and shadow wrath use real saved effect owners.
local component = require("constants.component")
local dithmenos = require("policy.religion.wrath.dithmenos")
local fedhas = require("policy.religion.wrath.fedhas")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jiyva = require("policy.religion.wrath.jiyva")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Each case gets a real player and source-sized progression and penance.
local function player_at(ctx, x)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.ACTOR, {
        kind_id = monsters.MONS_HUMAN,
        speed = 10,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 10,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = x,
        y = 10,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        penance = {
            [gods.JIYVA] = 10,
        },
    })

    return player
end

-- Fix only card draws so the status and summon owners retain their streams.
local function with_draws(ctx, draws)
    local owner = setmetatable({}, { __index = ctx })
    local used = 0

    -- Assert each selected card bound while forwarding all other streams.
    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        used = used + 1
        local value = draws[used]

        harness.truthy(value ~= nil, "missing nature wrath draw")
        harness.truthy(value >= 0 and value < bound,
            "nature wrath draw outside source bound")

        return value
    end

    -- Make the source branch roll count visible to assertions.
    function owner:draws_used()
        return used
    end

    return owner
end

-- Three failed primary gates lead to a saved contamination increment.
local function jiyva_contaminates(ctx)
    local player = player_at(ctx, 10)
    local owner = with_draws(ctx, { 1, 1, 1, 400, 1 })

    harness.truthy(jiyva.apply(owner, player))
    harness.equal(ctx:get(player, "zap.contamination").amount, 400)
    harness.equal(owner:draws_used(), 5)
end

-- A level-ten body gets two source-god slimes when the count roll is zero.
local function jiyva_summons(ctx)
    local player = player_at(ctx, 12)
    local site = fixture.context(ctx, player)
    local owner = with_draws(site, {
        1, 1, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        1,
    })

    harness.truthy(jiyva.apply(owner, player))

    local summoned = ctx:query({ component.SUMMON })
    local created = 0

    for _, creature in ipairs(summoned) do
        if ctx:get(creature, component.SUMMON).source_id == gods.JIYVA then
            created = created + 1
            harness.equal(ctx:get(creature, component.ACTOR).kind_id,
                monsters.MONS_FLOATING_EYE)
        end
    end

    harness.equal(created, 2)
end

-- The fourth Dithmenos slot reaches the saved alarm timer.
local function dithmenos_marks(ctx)
    local player = player_at(ctx, 15)
    local owner = with_draws(ctx, { 3, 0 })

    harness.truthy(dithmenos.apply(owner, player))
    harness.equal(ctx:get(player, component.TRAP_MARK).remaining_aut, 250)
    harness.equal(owner:draws_used(), 2)
end

-- Level one needs no random2avg count roll and sends three ordinary shadows.
local function dithmenos_shadows(ctx)
    local player = player_at(ctx, 16)
    local progress = ctx:get(player, component.PROGRESSION)

    progress.level = 1
    ctx:set(player, component.PROGRESSION, progress)

    local site = fixture.context(ctx, player)
    local owner = with_draws(site, {
        0, 2, 1,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
    })

    harness.truthy(dithmenos.apply(owner, player))

    local created = 0

    for _, creature in ipairs(ctx:query({ component.SUMMON })) do
        if ctx:get(creature, component.SUMMON).source_id == gods.DITHMENOS then
            created = created + 1
            harness.equal(ctx:get(creature, component.ACTOR).kind_id,
                monsters.MONS_SHADOW)
        end
    end

    harness.equal(created, 3)
end

-- The third slot delegates sleep eligibility and duration to its owner.
local function dithmenos_sleeps(ctx)
    local player = player_at(ctx, 17)
    local owner = with_draws(ctx, { 2, 0 })

    harness.truthy(dithmenos.apply(owner, player))
    harness.equal(ctx:get(player, component.PLAYER_SLEEP).remaining_aut, 50)
    harness.equal(owner:draws_used(), 2)
end

-- Both petrification phases reject source put_to_sleep before duration
-- rolls, so Dithmenos cannot leave contradictory saved player statuses.
local function dithmenos_petrification(ctx)
    for index, phase in ipairs({ "petrifying_aut", "petrified_aut" }) do
        local player = player_at(ctx, 17 + index)
        local owner = with_draws(ctx, { 2, 0 })
        local status = {
            petrifying_aut = 0,
            petrified_aut = 0,
        }

        status[phase] = 10
        ctx:add(player, component.PLAYER_PETRIFICATION, status)

        harness.truthy(dithmenos.apply(owner, player))
        harness.falsy(ctx:has(player, component.PLAYER_SLEEP))
        harness.equal(owner:draws_used(), 2)
    end
end

-- Independent player positions keep saved statuses and summons distinct.
function test.run(ctx)
    jiyva_contaminates(ctx)
    jiyva_summons(ctx)
    dithmenos_marks(ctx)
    dithmenos_shadows(ctx)
    dithmenos_sleeps(ctx)
    dithmenos_petrification(ctx)
end

return test
