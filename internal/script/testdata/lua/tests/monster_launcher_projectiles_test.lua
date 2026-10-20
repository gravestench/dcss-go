-- Both source bow and crossbow missiles share the launcher contact policy.
local harness = require("tests.harness")
local items = require("ids.items")
local projectiles = require("policy.combat.monster_projectiles")

local test = {}

-- A catalog launcher must resolve its missile policy before monster AI
-- commits a ranged action; source arrows and bolts use the same formula.
function test.run()
    for _, id in ipairs({ items.MI_ARROW, items.MI_BOLT }) do
        local effect = projectiles.effect(id)

        harness.truthy(type(effect.resolve_launcher) == "function",
            "launcher missile resolves " .. id)
        harness.truthy(type(effect.validate_launcher) == "function",
            "launcher missile validates " .. id)
        effect.validate_launcher({ ego = "" })
    end
end

return test
