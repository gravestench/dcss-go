local common = {
    LOS_RADIUS = 7,
}

-- Example: Searching { "MH_NATURAL" } for "MH_NATURAL" succeeds; an absent tag fails.
-- Treat missing catalog arrays as empty when testing traits shared by status rules.
function common.has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Status area effects use a seven-cell default LOS radius on the same level.
function common.visible(ctx, origin, position, radius)
    return position.level_id == origin.level_id and
        ctx:visible(origin.level_id, origin.x, origin.y,
            radius or common.LOS_RADIUS, position.x, position.y)
end

-- Use Chebyshev distance for the square LOS footprint shared by area statuses.
function common.distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

return common
