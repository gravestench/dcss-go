local common = {
    LOS_RADIUS = 7,
}

function common.has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

function common.visible(ctx, origin, position, radius)
    return position.level_id == origin.level_id and
        ctx:visible(origin.level_id, origin.x, origin.y,
            radius or common.LOS_RADIUS, position.x, position.y)
end

function common.distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

return common
