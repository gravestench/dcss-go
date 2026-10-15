local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local stab = require("policy.combat.stab")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local rat = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })
    ctx:add(rat, component.MONSTER_STASIS, {
        hibernating = true,
    })

    local world = setmetatable({}, { __index = ctx })

    function world.random(_, stream, bound)
        harness.equal(stream, "melee", "stabbing uses the melee RNG")
        harness.truthy(bound > 0, "stabbing RNG bounds are positive")

        return 0
    end

    function world.visible()
        return true
    end

    local ordinary = {
        weapon_skill = "SK_UNARMED_COMBAT",
        weapon50 = 0,
        stealth50 = 0,
        dexterity = 10,
        using_weapon = false,
    }
    local sleeping = stab.prepare(world, player, rat, ordinary)

    harness.equal(sleeping.bonus, 1,
        "a sleeping monster is an automatic high-grade stab")
    harness.equal(stab.damage(world, player, ordinary, sleeping, 4), 4,
        "ordinary unarmed attacks get no good-stab damage")

    records.grant_acquired(ctx, player, mutations.MUT_PAWS, 1)

    local pounce = stab.prepare(world, player, rat, ordinary)

    harness.equal(stab.damage(world, player, ordinary, pounce, 4), 5,
        "paws give unarmed attacks the source good-stab bonus")
    harness.equal(stab.message(world, player, pounce, "rat"),
        "You pounce on the unaware rat!",
        "paws use the source pounce message for helpless targets")

    ctx:set(rat, component.MONSTER_STASIS, {
        petrifying_aut = 20,
    })

    local awake = stab.prepare(world, player, rat, ordinary)

    harness.equal(awake.bonus, 4,
        "petrifying enemies have a weaker stab opening")
end

return test
