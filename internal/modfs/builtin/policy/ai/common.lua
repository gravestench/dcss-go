local ai = {}

function ai.distance(x1, y1, x2, y2)
    return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
end

function ai.adjacent(a, b)
    return a.level_id == b.level_id and
        ai.distance(a.x, a.y, b.x, b.y) == 1
end

function ai.leader_position(ctx, entity, level_id)
    local follower = ctx:get(entity, "core.follower")

    if not follower then
        return nil, nil
    end

    local leader = follower.leader
    local position = ctx:get(leader, "core.position")

    if not position or position.level_id ~= level_id then
        return nil, nil
    end

    return position, leader
end

function ai.forget(state)
    state.behavior = "wander"
    state.target_x = 0
    state.target_y = 0
    state.memory_until_aut = 0
end

return ai
