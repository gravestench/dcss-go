-- Dithmenos's second wrath slot selects Dungeon-depth mobile monsters,
-- then leaves timed, hostile, god-attributed summons on the current floor.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local dithmenos = require("policy.religion.wrath.dithmenos")
local fixture = require("tests.monster_ally_support_fixture")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local test = {}

-- Production actor and progression state feed the source XL-based draw.
local function player_at(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 50, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })

    return player
end

-- Fix the branch gate, then take minimum count, pool, and placement draws.
-- The recorded bounds expose the source's rounded count before sampling.
local function with_draws(ctx)
    local owner = setmetatable({}, { __index = ctx })
    local bounds = {}

    function owner:random(stream, bound)
        if stream ~= streams.CARDS then
            return ctx:random(stream, bound)
        end

        bounds[#bounds + 1] = bound

        if #bounds == 1 then
            return 1
        end

        return 0
    end

    function owner:bounds()
        return bounds
    end

    return owner
end

-- Wrath creatures use ordinary monster equipment generation. The saved
-- carried weapon remains attached to the same summon after creation.
local function wrath_loadout(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 60, 30)
    local owner = fixture.context(ctx, player)
    local creature = summons.hostile(owner, player,
        gods.BEOGH, monsters.MONS_ORC)

    harness.truthy(creature)

    local carried = 0

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        if ctx:get(entity, component.CARRIED_BY).holder == creature then
            carried = carried + 1
        end
    end

    harness.truthy(carried > 0,
        "an orc summoned by wrath keeps its generated weapon")
end

-- Source power at XL1 looks at Dungeon depth six and summons two mobile
-- bodies with a level-four abjuration timer (360 aut), not permanent wrath.
function test.run(ctx)
    wrath_loadout(ctx)

    local player = player_at(ctx)
    local owner = with_draws(fixture.context(ctx, player))

    harness.truthy(dithmenos.apply(owner, player))

    local created = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon.source_id == gods.DITHMENOS then
            created = created + 1
            harness.equal(summon.attitude, attitudes.HOSTILE)
            harness.equal(summon.expires_aut, 360)

            local actor = ctx:get(entity, component.ACTOR)
            local definition = catalog.get(categories.MONSTERS,
                actor.kind_id)

            for _, flag in ipairs(definition.flags or {}) do
                harness.falsy(flag == flags.STATIONARY)
            end
        end
    end

    harness.equal(created, 2)
    harness.equal(owner:bounds()[1], 4)
    harness.equal(owner:bounds()[2], 4)
end

return test
