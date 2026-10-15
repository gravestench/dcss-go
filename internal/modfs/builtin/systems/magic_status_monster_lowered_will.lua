local component = require("constants.component")
local lowered_will = require("policy.magic.effects.statuses.lowered_will")

local system = {}

function system.update(ctx, monster)
    if ctx:has(monster, component.AI) then
        lowered_will.tick(ctx, monster)
    end
end

register.system({
    id = "magic.monster_lowered_will.tick",
    scope = "active",
    query = { component.MONSTER_LOWERED_WILL },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
