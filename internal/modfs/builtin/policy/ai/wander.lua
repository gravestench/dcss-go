local common = require("policy.ai.common")

local wander = {}

-- A follower inherits a reachable leader target before independent wandering.
local function choose_band_target(ctx, state, position, leader)
    local level_id = position.level_id

    if common.distance(position.x, position.y, leader.x, leader.y) > 13 then
        state.target_x = leader.x
        state.target_y = leader.y
        return
    end

    local candidates = {}

    -- Compute's radius-seven mask has no visible cells outside this square.
    -- Row-major enumeration preserves the Go candidate ordering.
    for y = position.y - 7, position.y + 7 do
        for x = position.x - 7, position.x + 7 do
            if ctx:walkable(level_id, x, y) and
                common.distance(x, y, leader.x, leader.y) < 6 and
                (x ~= position.x or y ~= position.y) and
                not ctx:actor_at(level_id, x, y) and
                ctx:visible(level_id, position.x, position.y, 7, x, y) then
                candidates[#candidates + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    if #candidates == 0 then
        state.target_x = leader.x
        state.target_y = leader.y
        return
    end

    local index = ctx:random("ai", #candidates) + 1
    state.target_x = candidates[index].x
    state.target_y = candidates[index].y
end

-- Retarget a wandering band from its leader or an occasional AI roll, avoiding a fixed stale destination.
-- Example: wander.update(ctx, monster, state, position) keeps a band's pursuit target in sync.
function wander.update(ctx, entity, state, position)
    local leader = common.leader_position(ctx, entity, position.level_id)
    local retarget = state.target_x == 0 and state.target_y == 0

    if leader then
        local distance = common.distance(position.x, position.y, leader.x, leader.y)
        local leader_target_in_range = state.target_x == leader.x and
            state.target_y == leader.y and distance < 6

        if distance >= 6 or leader_target_in_range then
            retarget = true
        end
    end

    if not retarget then
        retarget = ctx:random("ai", 20) == 0
    end

    if not retarget then
        return
    end

    state.target_x = 0
    state.target_y = 0

    if leader then
        choose_band_target(ctx, state, position, leader)
        return
    end

    for _ = 1, 150 do
        local dx = ctx:random("ai", 13)
        local dy = ctx:random("ai", 13)
        local x = position.x + dx - 6
        local y = position.y + dy - 6

        if (x ~= position.x or y ~= position.y) and
            ctx:walkable(position.level_id, x, y) then
            state.target_x = x
            state.target_y = y
            return
        end
    end
end

return wander
