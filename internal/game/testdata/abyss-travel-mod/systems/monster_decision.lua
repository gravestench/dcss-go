-- Structural Abyss travel tests keep generated monsters in ECS but give
-- them WAIT intents. Their unrelated combat spellbooks cannot interrupt
-- the portal and save path being exercised by those tests.
local component = require("constants.component")
local intents = require("constants.intent")

local system = {}

-- Preserve the production decision slot so later monster systems still
-- receive a legal intent and the relative stair system order is unchanged.
function system.update(ctx, entity)
    if not ctx:has(entity, component.AI) then
        return
    end

    local health = ctx:get(entity, component.HEALTH)

    if health and health.current > 0 and
        not ctx:has(entity, component.INTENT) then
        ctx:add(entity, component.INTENT, {
            kind = intents.MONSTER_WAIT,
        })
    end
end

register.system({
    id = "monster.decision",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "world.stairs" },
    update = system.update,
})

return system
