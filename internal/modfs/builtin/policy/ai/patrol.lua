-- A source patrol point bounds idle wandering even after a long chase.
-- The anchor is actor-owned saved state; no map-global route is needed.
local component = require("constants.component")

local patrol = {}

-- Pick a free, visible cell near the authored anchor. Returning toward the
-- anchor when no candidate fits keeps an isolated patrol from drifting.
function patrol.target(ctx, entity, state, position)
    local anchor = ctx:get(entity, component.MONSTER_PATROL)

    if not anchor or anchor.level_id ~= position.level_id then
        return false
    end

    local candidates = {}
    local anchor_visible = ctx:visible(anchor.level_id,
        position.x, position.y, 7, anchor.x, anchor.y)

    for y = anchor.y - 7, anchor.y + 7 do
        for x = anchor.x - 7, anchor.x + 7 do
            if (x ~= position.x or y ~= position.y) and
                ctx:walkable(anchor.level_id, x, y) and
                not ctx:actor_at(anchor.level_id, x, y) and
                ctx:visible(anchor.level_id, anchor.x, anchor.y,
                    7, x, y) and
                (anchor_visible or ctx:visible(anchor.level_id,
                    position.x, position.y, 7, x, y)) then
                candidates[#candidates + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    if #candidates == 0 then
        state.target_x = anchor.x
        state.target_y = anchor.y
        return true
    end

    local target = candidates[ctx:random("ai", #candidates) + 1]

    state.target_x = target.x
    state.target_y = target.y

    return true
end

return patrol
