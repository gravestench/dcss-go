local component = require("constants.component")

local system = {}

function system.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    for _, marker in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if ctx:aut() >= state.expires_aut then
            if ctx:cell(state.level_id, state.x, state.y) ==
                state.changed_feature then
                ctx:set_cell(state.level_id, state.x, state.y,
                    state.original_feature)
            end

            ctx:destroy(marker)
        end
    end
end

register.system({
    id = "world.temporary_terrain",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
