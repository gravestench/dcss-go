local component = require("constants.component")
local enchant = require("policy.combat.monster_enchant")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local monster = harness.actor_with(ctx, component.MONSTER_ENCHANT, {
        blind_aut = 20,
        corrosion_aut = 0,
    })

    harness.truthy(enchant.can_dispel(ctx, monster),
        "a magically blinded monster can be unravelled")

    local definition = {
        name = "test monster",
    }

    harness.truthy(enchant.dispel(ctx, monster, definition),
        "dispel should remove the active enchantment")
    harness.falsy(ctx:has(monster, component.MONSTER_ENCHANT),
        "dispel should remove the saved enchantment")
    harness.falsy(enchant.can_dispel(ctx, monster),
        "a monster with no enchantments is not an unravel target")
end

return test
