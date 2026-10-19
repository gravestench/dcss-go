local component = require("constants.component")
local chaos = require("policy.combat.monster_target_brands.chaos_status")

local system = {}

-- Theory of operation: Chaos's temporary agility ages before AI chooses an
-- intent. Permanent shape changes run in the separate shapeshifter system.
function system.update(ctx, monster)
    if ctx:has(monster, component.AI) then
        chaos.tick(ctx, monster, 10)
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
