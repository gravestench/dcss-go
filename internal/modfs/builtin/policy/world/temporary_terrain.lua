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

-- Restore only a cell that still has the marker's changed feature. A
-- later permanent spell or vault edit wins over this older timer.
function terrain.restore(ctx, marker, state)
    if ctx:cell(state.level_id, state.x, state.y) ==
        state.changed_feature then
        ctx:set_cell(state.level_id, state.x, state.y,
            state.original_feature)
    end

    ctx:destroy(marker)
end

-- Source terrain markers end when their caster dies or becomes pacified.
-- Compare saved actor IDs, not kind IDs: another Warden keeps its seals.
function terrain.release_source(ctx, actor)
    local source_id = ctx:id(actor)

    for _, marker in ipairs(ctx:query({ component.TEMPORARY_TERRAIN })) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        if state.source_actor_id == source_id then
            terrain.restore(ctx, marker, state)
        end
    end
end

return terrain
