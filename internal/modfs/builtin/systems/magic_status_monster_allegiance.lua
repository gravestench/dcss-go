local component = require("constants.component")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local system = {}

-- Theory of operation: Expired allegiance is removed before AI chooses friend or foe.
-- Temporary allegiance expires before AI chooses a target for the monster.
function system.update(ctx, entity, elapsed_aut)
    if ctx:has(entity, component.AI) then
        allegiance.tick(ctx, entity, elapsed_aut)
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
