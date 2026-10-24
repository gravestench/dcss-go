-- Both source bow and crossbow missiles share the launcher contact policy.
local harness = require("tests.harness")
local items = require("ids.items")
local projectiles = require("policy.combat.monster_projectiles")
local ranged = require("policy.combat.ranged")

local test = {}

-- A penetration launcher does not enter the shield contest. An otherwise
-- identical ordinary shot is blocked by this high-shield defender.
local function penetration_bypasses_shield()
    local ctx = {}

    function ctx.random(_, _, bound)
        if bound == 100 then
            return 99
        end

        if bound > 100 then
            return bound - 1
        end

        return 0
    end

    local defense = {
        ev = 0,
        shield_class = 200,
        shield_blocks = 0,
        ac = 0,
        gdr = 0,
    }
    local shot = {
        hd = 1,
        weapon_damage = 2,
        projectile_damage = 2,
        natural_damage = 4,
    }

    harness.equal(ranged.shot(ctx, shot, defense).kind, "block",
        "ordinary launcher shot faces the defender's shield")

    shot.penetrating = true

    harness.equal(ranged.shot(ctx, shot, defense).kind, "hit",
        "penetration launcher ignores the shield contest")
end

-- A catalog launcher must resolve its missile policy before monster AI
-- commits a ranged action; source arrows and bolts use the same formula.
function test.run()
    penetration_bypasses_shield()
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
