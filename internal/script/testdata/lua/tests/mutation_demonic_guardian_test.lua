local causes = require("constants.damage_causes")
local component = require("constants.component")
local guardian = require("policy.mutations.effects.damage.demonic_guardian")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local summons = require("policy.magic.effects.summons.common")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 100,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 9,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    records.grant_innate(ctx, player,
        mutations.MUT_DEMONIC_GUARDIAN, 1)

    local spawned = {}
    local world = setmetatable({}, { __index = ctx })
    local original_spawn = summons.spawn

    function world.player()
        return player
    end

    function world.random(_, _, bound)
        harness.truthy(bound > 0, "guardian random bound is positive")

        return 0
    end

    function world.emit()
    end

    summons.spawn = function(_, owner, source, kind, duration, cap)
        spawned[#spawned + 1] = {
            owner = owner,
            source = source,
            kind = kind,
            duration = duration,
            cap = cap,
        }

        return ctx:create()
    end

    guardian.on_damage(world, player, 60, causes.HIT)

    harness.equal(#spawned, 1,
        "a severe non-poison hit summons one guardian")
    harness.equal(spawned[1].kind, monsters.MONS_QUASIT,
        "mutation one at XL9 selects the source first-tier demon")
    harness.equal(spawned[1].cap, 1,
        "guardian summons keep a single active creature")
    harness.equal(ctx:get(player, component.DEMONIC_GUARDIAN).cooldown_aut,
        10, "the source cooldown starts at mutation level turns")

    guardian.on_damage(world, player, 60, causes.HIT)
    harness.equal(#spawned, 1,
        "damage during the cooldown does not summon twice")

    guardian.tick(world, player, 10)
    guardian.on_damage(world, player, 60, causes.POISON)
    harness.equal(#spawned, 1,
        "poison never triggers a demonic guardian")

    guardian.on_damage(world, player, 60, causes.HIT)
    harness.equal(#spawned, 2,
        "the guardian can return after its saved cooldown expires")

    summons.spawn = original_spawn
end

return test
