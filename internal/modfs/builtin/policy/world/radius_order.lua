-- Match the source radius iterator's cell order when a sequence of nearby
-- actors consumes RNG. Stable spatial order survives ECS storage changes.
local order = {}

-- The iterator visits absolute y, then absolute x, then quadrant signs.
-- Entity ID breaks a same-cell tie without depending on query order.
function order.before(origin, left, right)
    local left_dy = math.abs(left.y - origin.y)
    local right_dy = math.abs(right.y - origin.y)

    if left_dy ~= right_dy then
        return left_dy < right_dy
    end

    local left_dx = math.abs(left.x - origin.x)
    local right_dx = math.abs(right.x - origin.x)

    if left_dx ~= right_dx then
        return left_dx < right_dx
    end

    local left_x = left.x < origin.x and 1 or 0
    local right_x = right.x < origin.x and 1 or 0

    if left_x ~= right_x then
        return left_x < right_x
    end

    local left_y = left.y < origin.y and 1 or 0
    local right_y = right.y < origin.y and 1 or 0

    if left_y ~= right_y then
        return left_y < right_y
    end

    return left.id < right.id
end

return order
