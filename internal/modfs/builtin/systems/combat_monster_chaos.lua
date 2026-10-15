local component = require("constants.component")
local chaos = require("policy.combat.player_brands.chaos_status")

local system = {}

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
