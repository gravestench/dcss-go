local component = require("constants.component")
local infestation = require("policy.magic.effects.statuses.infestation")
local system = {}

-- Theory of operation: Infestation is aged before the next monster intent is chosen.
-- Infestation status advances before the monster's next decision.
function system.update(ctx, actor)
    if ctx:has(actor, component.AI) then
        infestation.tick(ctx, actor)
    end
end

register.system({
    id = "magic.monster_infestation.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
