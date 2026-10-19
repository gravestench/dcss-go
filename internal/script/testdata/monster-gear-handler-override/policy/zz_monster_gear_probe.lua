-- The probe reads a Goblin loadout after handler replacement.
-- Example: test.monster_gear_override returns WPN_CLUB as the primary item.

local gear = require("policy.population.gear")
local monsters = require("ids.monsters")

local probe = {}

-- Ask the production gear selector for a goblin and expose its primary item,
-- verifying the mod handler replaced the embedded one at lookup time.
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
