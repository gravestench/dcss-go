
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local sanguine = require("policy.character.sanguine_armour")
local player_health = require("policy.combat.player_health")
local harness = require("tests.harness")

local test = {}

-- Sanguine Armour grants no AC before activation.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 21,
        max = 30,
    })
    ctx:add(player, component.SANGUINE_ARMOUR, {
        remaining_aut = 0,
    })
    records.grant_acquired(ctx, player,
        mutations.MUT_SANGUINE_ARMOUR, 1)

    harness.equal(effects.full_sum(ctx, player,
        capabilities.AC_FULL_X100), 0,
        "Sanguine Armour grants no AC before activation")

    player_health.damage(ctx, player, 7)

    -- The aura activation threshold and timer are checked separately from its AC formula.
    harness.equal(ctx:get(player,
        component.SANGUINE_ARMOUR).remaining_aut, 60,
        "injury below two-thirds HP activates a 60-to-100 aut timer")
    harness.equal(effects.full_sum(ctx, player,
        capabilities.AC_FULL_X100), 600,
        "level-one Sanguine Armour grants six AC")

    sanguine.tick(ctx, player, 10)

    harness.equal(ctx:get(player,
        component.SANGUINE_ARMOUR).remaining_aut, 60,
        "low HP refreshes the aura every player reaction")

    local health = ctx:get(player, component.HEALTH)

    health.current = 21
    ctx:set(player, component.HEALTH, health)
    sanguine.tick(ctx, player, 10)

    -- Healing does not remove armour mid-reaction; it schedules expiry on the next action.
    harness.equal(ctx:get(player,
        component.SANGUINE_ARMOUR).remaining_aut, 1,
        "healing above two-thirds HP leaves a one-aut expiry")

    sanguine.tick(ctx, player, 10)

    harness.equal(ctx:get(player,
        component.SANGUINE_ARMOUR).remaining_aut, 0,
        "Sanguine Armour expires on the next action")
    harness.equal(effects.full_sum(ctx, player,
        capabilities.AC_FULL_X100), 0,
        "expired blood armour grants no AC")

    local stronger = ctx:create()

    ctx:add(stronger, component.HEALTH, {
        current = 20,
        max = 30,
    })
    ctx:add(stronger, component.SANGUINE_ARMOUR, {
        remaining_aut = 0,
    })
    records.grant_acquired(ctx, stronger,
        mutations.MUT_SANGUINE_ARMOUR, 3)

    sanguine.on_damage(ctx, stronger, 1)

    harness.equal(effects.full_sum(ctx, stronger,
        capabilities.AC_FULL_X100), 1200,
        "level-three Sanguine Armour grants twelve AC")
end

return test
