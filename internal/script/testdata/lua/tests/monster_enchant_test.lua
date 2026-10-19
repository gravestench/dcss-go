
local component = require("constants.component")
local enchant = require("policy.combat.monster_enchant")
local harness = require("tests.harness")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- Dispel should remove the saved enchantment.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local monster = harness.actor_with(ctx, component.MONSTER_ENCHANT, {
        blind_aut = 20,
        corrosion_aut = 0,
    })

    harness.truthy(enchant.can_dispel(game, monster),
        "a magically blinded monster can be unravelled")

    local definition = {
        name = "test monster",
    }

    harness.truthy(enchant.dispel(game, monster, definition),
        "dispel should remove the active enchantment")
    harness.falsy(ctx:has(monster, component.MONSTER_ENCHANT),
        "dispel should remove the saved enchantment")
    harness.falsy(enchant.can_dispel(game, monster),
        "a monster with no enchantments is not an unravel target")
end

return test
