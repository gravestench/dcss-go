-- Example: A trail near the east edge turns inward rather than stepping beyond the grid.
local corridors = {}

local width = 80
local height = 70

-- Near-edge trail growth turns back toward the playable interior.
local function inward(position, direction)
    if position.x < 4 then
        direction = { x = 1, y = 0 }
    end

    if position.x > width - 1 - 4 then
        direction = { x = -1, y = 0 }
    end

    if position.y < 4 then
        direction = { x = 0, y = 1 }
    end

    if position.y > height - 1 - 4 then
        direction = { x = 0, y = -1 }
    end

    return direction
end

-- Bias a near-edge step inward while retaining source randomness in the interior.
function corridors.trail_direction(builder, position, bound)
    local direction = 0

    if position < 15 then
        direction = 1
    elseif position > bound - 15 then
        direction = -1
    end

    if direction == 0 or builder:chance_in(2, 5) then
        return builder:roll(2) == 0 and -1 or 1
    end

    return direction
end

-- Choose an axis before selecting sign so cardinal directions share the intended distribution.
function corridors.choose_direction(builder, position)
    if builder:roll(2) == 0 then
        return {
            x = corridors.trail_direction(builder, position.x, width),
            y = 0,
        }
    end

    return {
        x = 0,
        y = corridors.trail_direction(builder, position.y, height),
    }
end

-- Leave a cell beyond the segment in bounds so corridor growth can detect an existing floor safely.
function corridors.carve_segment(builder, position, direction, length)
    for _ = 1, length do
        direction = inward(position, direction)
        local next_cell = {
            x = position.x + direction.x,
            y = position.y + direction.y,
        }
        local beyond = {
            x = next_cell.x + direction.x,
            y = next_cell.y + direction.y,
        }

        if not builder:inside(next_cell) or not builder:inside(beyond) then
            return nil, "trail escaped the map"
        end

        if builder:cell(beyond.x, beyond.y) == "." and
            not builder:one_in(builder.intersect_in) then
            break
        end

        position = next_cell

        if builder:cell(position.x, position.y) == "#" then
            builder:set(position.x, position.y, ".")
        end
    end

    return position, nil
end

-- Join stair anchors with an orthogonal walk, drawing axis order when both directions remain.
-- Carve only rock between stair anchors; existing floor remains intact.
function corridors.connect(builder, from, to)
    local position = {
        x = from.x,
        y = from.y,
    }

    while position.x ~= to.x or position.y ~= to.y do
        local horizontal = position.x ~= to.x
        local vertical = position.y ~= to.y

        if horizontal and vertical then
            horizontal = builder:roll(2) == 0
        end

        if horizontal then
            position.x = position.x + (position.x < to.x and 1 or -1)
        else
            position.y = position.y + (position.y < to.y and 1 or -1)
        end

        if builder:cell(position.x, position.y) == "#" then
            builder:set(position.x, position.y, ".")
        end
    end
end

return corridors
