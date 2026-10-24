-- Exercise the real Yredelemnul derived-undead owner in the game world.
-- The policy adds no test-only component or monster definition.
local zombies = require("policy.religion.wrath.yredelemnul.zombies")

local test = {}

-- A fixed low level keeps the source Dungeon base range inside the
-- committed population table; the ordinary game RNG chooses its form.
function test.run(ctx)
    local player = ctx:player()

    if not zombies.spawn(ctx, player, 1) then
        error("Yredelemnul created no derived undead")
    end

    return {}
end

register.policy({
    id = "test.yred_derived_undead",
    run = test.run,
})

return test
