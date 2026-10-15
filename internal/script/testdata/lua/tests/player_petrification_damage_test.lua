local component = require("constants.component")
local harness = require("tests.harness")
local petrification = require("policy.combat.player_petrification")
local player_health = require("policy.combat.player_health")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    harness.equal(type(petrification.reduce_damage), "function",
        "petrification exposes the source damage reduction")
    harness.equal(petrification.reduce_damage(ctx, player, 15), 15,
        "ordinary damage is unchanged")

    ctx:add(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 20,
        petrified_aut = 0,
    })

    harness.equal(petrification.reduce_damage(ctx, player, 15), 10,
        "petrifying reduces ordinary damage by one third")

    ctx:set(player, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 0,
        petrified_aut = 60,
    })

    harness.equal(petrification.reduce_damage(ctx, player, 15), 7,
        "fully petrified halves ordinary damage")

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })

    player_health.damage(ctx, player, 15)

    harness.equal(ctx:get(player, component.HEALTH).current, 23,
        "the shared player damage path applies petrification protection")
end

return test
