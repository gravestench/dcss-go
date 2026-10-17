local causes = require("constants.damage_causes")
local component = require("constants.component")
local harness = require("tests.harness")
local player_health = require("policy.combat.player_health")

local test = {}

local function sleeping_player(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(player, component.PLAYER_SLEEP, {
        remaining_aut = 50,
        immunity_aut = 0,
    })

    return player
end

function test.run(ctx)
    local hit = sleeping_player(ctx)

    player_health.damage(ctx, hit, 5)

    local awakened = ctx:get(hit, component.PLAYER_SLEEP)

    harness.equal(awakened.remaining_aut, 0,
        "a nonfatal hit wakes a sleeping player")
    harness.truthy(awakened.immunity_aut >= 30,
        "waking from damage grants source sleep immunity")

    local poisoned = sleeping_player(ctx)

    player_health.damage(ctx, poisoned, 5, false, nil,
        causes.POISON)

    harness.equal(ctx:get(poisoned,
        component.PLAYER_SLEEP).remaining_aut, 50,
        "poison damage does not wake a sleeping player")
end

return test
