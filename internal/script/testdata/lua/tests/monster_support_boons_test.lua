local boons = require("policy.combat.monster_support.boons")
local chaos = require("policy.combat.player_brands.chaos_status")
local chaos_effects = require("constants.chaos_effects")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local energy = require("policy.monster_energy")
local enchant = require("policy.combat.monster_enchant")
local intent = require("constants.intent")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- A spell and a Chaos brand grant the same saved Haste and Might state.
-- Their consumers must not depend on which producer supplied the boon.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local monster = ctx:create()

    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    boons.haste(ctx, monster, 40)
    chaos.apply(ctx, monster, chaos_effects.MIGHT, 50)

    harness.equal(boons.speed(ctx, monster, 10), 15,
        "spell Haste changes action speed")
    harness.equal(boons.damage(ctx, monster, 10), 15,
        "Chaos Might uses the shared melee projection")
    harness.truthy(ctx:has(monster, component.MONSTER_BOONS),
        "both boons have one saved owner")

    local chaos_record = ctx:get(monster, component.MONSTER_CHAOS)

    harness.falsy(chaos_record and chaos_record.might_aut,
        "Chaos does not keep a second Might timer")

    boons.tick(ctx, monster, 40)

    harness.equal(boons.speed(ctx, monster, 10), 10,
        "Haste expires independently")
    harness.equal(boons.damage(ctx, monster, 10), 15,
        "Might remains until its own timer expires")

    boons.tick(ctx, monster, 10)

    harness.falsy(ctx:has(monster, component.MONSTER_BOONS),
        "empty boon state leaves the actor")

    boons.swift(ctx, monster, 30)

    local move = energy.spend(ctx, {
        actor = ctx:id(monster),
        kind_id = monsters.MONS_RAT,
        intent = intent.MOVE,
        points = energy.threshold,
    })

    harness.equal(move.cost, 7,
        "Sprint lowers movement energy by three only")

    local attack = energy.spend(ctx, {
        actor = ctx:id(monster),
        kind_id = monsters.MONS_RAT,
        intent = intent.MONSTER_MELEE,
        points = energy.threshold,
    })

    harness.equal(attack.cost, 10,
        "Sprint leaves attack energy unchanged")

    harness.truthy(enchant.can_dispel(game, monster),
        "Sprint is a dispellable magical boon")
    harness.truthy(enchant.dispel(game, monster, {
        name = "rat",
    }), "Unravelling strips the boon")
    harness.falsy(ctx:has(monster, component.MONSTER_BOONS),
        "dispel removes the saved owner")
end

return test
