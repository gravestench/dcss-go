-- Theory of operation: vine heads choose anchored moves before the
-- ordinary monster AI runs. Connector actors simply wait; neither type
-- needs a special case in the generic decision or movement owner.
local component = require("constants.component")
local intent = require("constants.intent")
local chain = require("policy.combat.monster_plants.vine_chain")

local system = {}

-- Saved vine state selects a head action or connector wait intent.
function system.update(ctx, entity)
    if ctx:has(entity, component.INTENT) then
        return
    end

    local action

    if ctx:has(entity, component.MONSTER_VINE) then
        action = chain.act(ctx, entity)
    elseif ctx:has(entity, component.MONSTER_VINE_SEGMENT) then
        action = { kind = intent.MONSTER_WAIT }
    end

    if action then
        ctx:add(entity, component.INTENT, action)
    end
end

register.system({
    id = "combat.monster_vine_decision",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
