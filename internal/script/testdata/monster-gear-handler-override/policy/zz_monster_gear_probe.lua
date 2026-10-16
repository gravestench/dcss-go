local gear = require("policy.population.gear")
local monsters = require("ids.monsters")

local probe = {}

function probe.run(ctx)
    local loadout = gear.loadout(ctx, monsters.MONS_GOBLIN, 1)

    return {
        kind_id = loadout.primary.kind_id,
    }
end

register.policy({
    id = "test.monster_gear_override",
    run = probe.run,
})

return probe
