-- Timed and conditional portals keep their live source coordinate on an
-- ECS entity, separate from the level's terrain and DES marker record.
-- Xom slides all three representations together before a later visit.
local component = require("constants.component")

local portals = {}

local portal_components = {
    component.WORLD_BAZAAR_PORTAL,
    component.WORLD_SEWER_PORTAL,
    component.WORLD_OSSUARY_PORTAL,
    component.WORLD_WIZLAB_PORTAL,
    component.WORLD_DESOLATION_PORTAL,
    component.WORLD_GAUNTLET_PORTAL,
    component.WORLD_BAILEY_PORTAL,
    component.WORLD_ICE_CAVE_PORTAL,
    component.WORLD_VOLCANO_PORTAL,
    component.WORLD_TROVE_PORTAL,
}

-- Keep the original entity and clock; only its authoritative entrance
-- coordinate changes. The grid command moves the glyph and marker record.
function portals.move(ctx, level_id, from_x, from_y, to_x, to_y)
    for _, key in ipairs(portal_components) do
        for _, entity in ipairs(ctx:query({ key })) do
            local state = ctx:get(entity, key)

            if state.level_id == level_id and
                state.x == from_x and state.y == from_y then
                state.x = to_x
                state.y = to_y
                ctx:set(entity, key, state)
            end
        end
    end
end

return portals
