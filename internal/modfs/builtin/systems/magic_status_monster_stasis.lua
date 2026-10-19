local component = require("constants.component")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local system = {}

-- Theory of operation: Stasis state is aged before AI tries to issue an intent.
-- Stasis is updated before AI can issue a new monster intent.
function system.update(ctx, entity)
    if ctx:has(entity, component.AI) then
        stasis.tick(ctx, entity)
    end
end

register.system({
    id = "magic.monster_stasis.tick",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.update,
})

return system
