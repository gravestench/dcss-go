local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local monster = harness.actor_with(ctx, component.MONSTER_VILE_CLUTCH, {
        remaining_aut = 20,
        held_aut = 0,
        escape_attempts = 0,
    })
    local definition = {
        ev = 12,
        size_id = "SIZE_MEDIUM",
    }

    harness.equal(defense.evasion(ctx, monster, definition), 2,
        "Vile Clutch should reduce medium monster EV")

    ctx:remove(monster, component.MONSTER_VILE_CLUTCH)
    harness.equal(defense.evasion(ctx, monster, definition), 12,
        "removing Vile Clutch should restore EV")
end

return test
