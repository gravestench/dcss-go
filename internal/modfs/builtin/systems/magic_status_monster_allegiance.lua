local component = require("constants.component")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        allegiance.tick(ctx, entity)
    end
end

register.system({
    id = "magic.monster_allegiance.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
