local component = require("constants.component")

local system = {}

function system.update(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() then
        return
    end

    local state = ctx:get(actor, component.CORROSION)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(actor, component.CORROSION)

        return
    end

    ctx:set(actor, component.CORROSION, state)
end

register.system({
    id = "character.corrosion",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "world.cloud.player_exposure" },
    update = system.update,
})

return system
