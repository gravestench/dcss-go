local component = require("constants.component")
local constructs = require("constants.monster_construct_components")

local system = {}

-- Druid's Call gives an offscreen beast a patrol destination. Keep the
-- ordinary AI movement and incapacitation checks; refresh its saved route
-- memory until arrival or sight lets normal enemy acquisition take over.
function system.update(ctx, entity)
    local call = ctx:get(entity, constructs.CALLED_BEAST)
    local position = ctx:get(entity, component.POSITION)
    local foe = ctx:entity(call.target_id)
    local target = foe and ctx:get(foe, component.POSITION)
    local health = foe and ctx:get(foe, component.HEALTH)

    if not target or not health or health.current <= 0 or
        target.level_id ~= position.level_id or
        position.x == call.x and position.y == call.y or
        ctx:visible(position.level_id, position.x, position.y, 7,
            target.x, target.y) then
        ctx:remove(entity, constructs.CALLED_BEAST)

        return
    end

    local ai = ctx:get(entity, component.AI)

    if ai then
        ai.behavior = "seek"
        ai.target_x = call.x
        ai.target_y = call.y
        ai.memory_until_aut = ctx:aut() + 250
        ctx:set(entity, component.AI, ai)
    end
end

register.system({
    id = "combat.called_beast.patrol",
    scope = "active",
    query = { constructs.CALLED_BEAST, component.POSITION },
    before = { "monster.decision" },
    update = system.update,
})

return system
