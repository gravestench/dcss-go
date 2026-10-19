local component = require("constants.component")
local chaos = require("policy.combat.monster_target_brands.chaos_status")

local system = {}

-- Theory of operation: Chaos duration and behavioral shift are committed before AI chooses the next intent.
-- Chaos status on monsters ticks before AI decides an intent.
function system.update(ctx, monster)
    if ctx:has(monster, component.AI) then
        chaos.tick(ctx, monster, 10)
        chaos.shift(ctx, monster)
    end
end

register.system({
    id = "combat.monster_chaos.tick",
    scope = "active",
    query = { component.MONSTER_CHAOS },
    before = { "monster.decision" },
    update = system.update,
})

return system
