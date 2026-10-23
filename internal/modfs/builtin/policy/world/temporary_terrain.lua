local component = require("constants.component")

local terrain = {}

-- Temporary terrain records retain the old feature so expiry can restore it.
-- Example: terrain.place(ctx, caster, kind, level_id, x, y, feature, aut) records restoration state.
function terrain.place(ctx, source_actor, source_kind_id,
    level_id, x, y, changed_feature, duration_aut)
    local original = ctx:cell(level_id, x, y)

    if not original or original == changed_feature or duration_aut < 1 then
        return false
    end

    for _, marker in ipairs(ctx:query({ component.TEMPORARY_TERRAIN })) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if state.level_id == level_id and state.x == x and state.y == y then
            return false
        end
    end

    local marker = ctx:create()
    local source_id = source_actor and ctx:id(source_actor) or 0

    ctx:add(marker, component.TEMPORARY_TERRAIN, {
        source_actor_id = source_id,
        source_kind_id = source_kind_id,
        level_id = level_id,
        x = x,
        y = y,
        original_feature = original,
        changed_feature = changed_feature,
        expires_aut = ctx:aut() + duration_aut,
    })

    ctx:set_cell(level_id, x, y, changed_feature)

    return true, marker
end

return terrain
