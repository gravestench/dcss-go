local component = require("constants.component")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        enfeeble.tick(ctx, entity)
    end
end

register.system({
    id = "magic.monster_enfeeble.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
