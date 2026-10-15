local component = require("constants.component")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local statuses = require("policy.magic.effects.statuses.player")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local monster = harness.actor_with(ctx, component.MONSTER_MASS_ENCHANT, {
        fear_aut = 20,
        anguish_aut = 0,
    })

    harness.truthy(mass.fear_active(ctx, monster),
        "saved fear should affect monster decisions")
    ctx:remove(monster, component.MONSTER_MASS_ENCHANT)
    harness.falsy(mass.fear_active(ctx, monster),
        "fear should end when its saved mark is removed")

    local player = harness.actor_with(ctx, component.MIASMA_SLOW, {
        remaining_aut = 20,
    })

    harness.truthy(statuses.slow_active(ctx, player),
        "saved miasma should slow player timing")
    ctx:remove(player, component.MIASMA_SLOW)
    harness.falsy(statuses.slow_active(ctx, player),
        "miasma slow should end with its saved duration")
end

return test
