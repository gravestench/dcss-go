
local component = require("constants.component")
local effects = require("constants.chaos_effects")
local harness = require("tests.harness")
local chaos = require("policy.combat.monster_target_brands.chaos_status")
local boons = require("policy.combat.monster_support.boons")

local test = {}

-- Chaos might does not stack with the source frenzy bonus.
function test.run(ctx)
    local monster = ctx:create()

    ctx:add(monster, component.ACTOR, {
        kind_id = "MONS_RAT",
        speed = 10,
    })

    chaos.apply(ctx, monster, effects.HASTE, 50)
    chaos.apply(ctx, monster, effects.MIGHT, 50)
    chaos.apply(ctx, monster, effects.AGILITY, 50)

    harness.equal(boons.speed(ctx, monster, 10), 15,
        "chaos haste increases monster speed")
    harness.equal(boons.damage(ctx, monster, 10), 15,
        "chaos might increases monster melee damage")
    harness.equal(chaos.evasion(ctx, monster, 5), 10,
        "chaos agility increases monster evasion")

    ctx:add(monster, component.MONSTER_ALLEGIANCE, {
        charm_aut = 0,
        frenzy_aut = 50,
        fatigue_aut = 0,
    })

    harness.equal(boons.damage(ctx, monster, 15), 15,
        "chaos might does not stack with the source frenzy bonus")

    chaos.tick(ctx, monster, 50)
    boons.tick(ctx, monster, 50)

    harness.falsy(ctx:has(monster, component.MONSTER_CHAOS),
        "chaos monster buffs expire from their ECS owner")
    harness.falsy(ctx:has(monster, component.MONSTER_BOONS),
        "generic monster boons expire from their ECS owner")

    chaos.make_shifter(ctx, monster)
    chaos.tick(ctx, monster, 1000)

    harness.truthy(chaos.shifter_active(ctx, monster),
        "a chaos shapeshifter remains a shapeshifter after ordinary turns")
end

return test
