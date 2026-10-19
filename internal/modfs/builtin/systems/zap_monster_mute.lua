local component = require("constants.component")

local system = {}

-- Theory of operation: The mute component expires before spell-using AI chooses an action.
-- Mute duration can clear before spell-using monster AI runs.
function system.update(ctx, monster, aut)
    local state = ctx:get(monster, component.MONSTER_MUTE)

    if not state then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_MUTE)
    else
        ctx:set(monster, component.MONSTER_MUTE, state)
    end
end

register.system({
    id = "zap.monster_mute.tick",
    scope = "active",
    query = { component.MONSTER_MUTE },
    before = { "monster.decision" },
    update = system.update,
})

return system
