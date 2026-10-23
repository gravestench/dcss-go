-- Every school in Wild Magic's destructive pool has a real combat outcome.
-- Production monster statuses and health components reveal each result.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local miscast = require("policy.magic.miscast")
local monsters = require("ids.monsters")
local schools = require("constants.spell_schools")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- One damage point survives zero-AC rat defenses at level nine and zero
-- fail draws; special schools instead leave their own saved status.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local cases = {
        { school = schools.CONJURATION, effect = "damage" },
        { school = schools.FIRE, effect = "damage" },
        { school = schools.ICE, effect = "damage" },
        { school = schools.EARTH, effect = "damage" },
        { school = schools.AIR, effect = "damage" },
        { school = schools.POISON, effect = "poison" },
        { school = schools.TRANSMUTATION, effect = "mutation" },
        { school = schools.HEXES, effect = "slow" },
        { school = schools.NECROMANCY, effect = "drain" },
    }

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Miscast tester",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        harness.truthy(stream == streams.CARDS or
            stream == streams.MELEE)

        if bound == 3 then
            return 1
        end

        return 0
    end

    for index, case in ipairs(cases) do
        local target = fixture.actor(ctx, monsters.MONS_RAT,
            7 + index, 8, 100)
        local applied = miscast.apply(owner, target, player,
            case.school, 9, 0, streams.CARDS)

        harness.truthy(applied)

        if case.effect == "damage" then
            harness.truthy(ctx:get(target, component.HEALTH).current < 100)
        elseif case.effect == "poison" then
            harness.truthy(ctx:has(target, component.PROJECTILE_POISON))
        elseif case.effect == "mutation" then
            harness.truthy(ctx:has(target, component.WRETCHED))
        elseif case.effect == "slow" then
            harness.truthy(ctx:has(target, component.PROJECTILE_SLOW))
        elseif case.effect == "drain" then
            harness.truthy(ctx:has(target, component.MONSTER_DRAINED))
        end
    end
end

return test
