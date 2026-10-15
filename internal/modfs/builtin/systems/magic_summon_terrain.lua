local component = require("constants.component")
-- Source: terrain.cc:temp_change_terrain and terrain-change-type.h.
-- A timed marker restores its original feature only while the changed
-- feature still occupies the cell. Another terrain mutation wins.
local system = {}

function system.update(ctx, active)
    if active ~= ctx:player() then
        return
    end

    for _, marker in ipairs(ctx:query({ component.SUMMON_TERRAIN })) do
        local state = ctx:get(marker, component.SUMMON_TERRAIN)

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
    id = "magic.summon.terrain",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
