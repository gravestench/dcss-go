local ids = require("constants.monster_construct_components")

local system = {}

function system.update(ctx, entity, aut)
    local state = ctx:get(entity, ids.RESISTANCE)

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(entity, ids.RESISTANCE)
    else
        ctx:set(entity, ids.RESISTANCE, state)
    end
end

register.system({
    id = "combat.monster_resistance.tick",
    scope = "active",
    query = { ids.RESISTANCE },
    before = { "monster.decision" },
    update = system.update,
})

return system
