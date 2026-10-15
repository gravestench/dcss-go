local component = require("constants.component")
local touch = require("policy.magic.effects.statuses.confusing_touch")
local system = {}

function system.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        touch.tick(ctx, entity)
    end
end

register.system({
    id = "magic.monster_confusion.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
