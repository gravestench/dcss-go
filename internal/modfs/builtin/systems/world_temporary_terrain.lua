local component = require("constants.component")
local temporary = require("policy.world.temporary_terrain")

local system = {}

-- Theory of operation: Expired markers restore only the feature they placed, preserving intervening map edits.
-- Expiry restores the old feature only if the temporary feature still occupies the cell.
function system.update(ctx, actor)
    if actor ~= ctx:player() then
        return
    end

    for _, marker in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if ctx:aut() >= state.expires_aut then
            temporary.restore(ctx, marker, state)
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
