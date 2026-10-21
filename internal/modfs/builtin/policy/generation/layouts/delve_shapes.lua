-- Source delve layouts use simple geometric rooms after winding passages
-- establish the level's routes. Keep these painters free of selection policy.
local shapes = {}

-- Inclusive rectangle painting clips to the mutable interior of a grid.
function shapes.box(builder, x1, y1, x2, y2, glyph)
    for y = math.max(1, math.floor(y1)),
        math.min(builder.height - 2, math.floor(y2)) do
        for x = math.max(1, math.floor(x1)),
            math.min(builder.width - 2, math.floor(x2)) do
            builder:set(x, y, glyph)
        end
    end
end

-- A source circle uses the same radius on both axes. The caller can choose
-- a replacement glyph, such as reserved room wall or playable floor.
function shapes.circle(builder, center_x, center_y, radius, glyph)
    for dy = -radius, radius do
        for dx = -radius, radius do
            if dx * dx + dy * dy <= radius * radius then
                shapes.box(builder, center_x + dx, center_y + dy,
                    center_x + dx, center_y + dy, glyph)
            end
        end
    end
end

-- Diamond rooms in Cocytus and cross arm ends use Manhattan distance.
function shapes.diamond(builder, center_x, center_y, radius, glyph)
    for dy = -radius, radius do
        for dx = -radius, radius do
            if math.abs(dx) + math.abs(dy) <= radius then
                shapes.box(builder, center_x + dx, center_y + dy,
                    center_x + dx, center_y + dy, glyph)
            end
        end
    end
end

-- Source make_round_box uses an ellipse with an extra half-cell of radius.
-- A cell is interior only when all eight neighbors remain in that ellipse.
local function ellipse_cell(dx, dy, radius)
    local width = radius + 0.5

    return (dx / width) ^ 2 + (dy / width) ^ 2 <= 1
end

local function round_kind(dx, dy, radius)
    if not ellipse_cell(dx, dy, radius) then
        return nil
    end

    for oy = -1, 1 do
        for ox = -1, 1 do
            if not ellipse_cell(dx + ox, dy + oy, radius) then
                return "wall"
            end
        end
    end

    return "floor"
end

-- A door candidate needs a straight wall segment and an existing passable
-- corridor immediately outside. The room does not dig a new corridor.
local function round_doors(builder, center_x, center_y, radius, wanted)
    local candidates = {}
    local doors = {}

    for dy = -radius, radius do
        for dx = -radius, radius do
            if round_kind(dx, dy, radius) == "wall" then
                local horizontal = round_kind(dx - 1, dy, radius) == "wall" and
                    round_kind(dx + 1, dy, radius) == "wall" and
                    round_kind(dx, dy - 1, radius) ~= "wall" and
                    round_kind(dx, dy + 1, radius) ~= "wall"
                local vertical = round_kind(dx, dy - 1, radius) == "wall" and
                    round_kind(dx, dy + 1, radius) == "wall" and
                    round_kind(dx - 1, dy, radius) ~= "wall" and
                    round_kind(dx + 1, dy, radius) ~= "wall"
                local x = center_x + dx
                local y = center_y + dy
                local outside = (horizontal and
                    ((not ellipse_cell(dx, dy - 1, radius) and
                        builder:cell(x, y - 1) == ".") or
                    (not ellipse_cell(dx, dy + 1, radius) and
                        builder:cell(x, y + 1) == "."))) or
                    (vertical and
                    ((not ellipse_cell(dx - 1, dy, radius) and
                        builder:cell(x - 1, y) == ".") or
                    (not ellipse_cell(dx + 1, dy, radius) and
                        builder:cell(x + 1, y) == ".")))

                if outside then
                    candidates[#candidates + 1] = {
                        dx = dx,
                        dy = dy,
                    }
                end
            end
        end
    end

    while #doors < wanted and #candidates > 0 do
        local index = builder:roll(#candidates) + 1
        local choice = table.remove(candidates, index)
        local next_to_door = false

        for _, placed in ipairs(doors) do
            if math.abs(placed.dx - choice.dx) +
                math.abs(placed.dy - choice.dy) == 1 then
                next_to_door = true
                break
            end
        end

        if not next_to_door then
            doors[#doors + 1] = choice
        end
    end

    return doors
end

-- The same shape can reserve a placeholder, paint a plain floor room, or
-- place a Zot chamber with two to four nonadjacent doors. A chamber with no
-- legal door leaves the placeholder untouched, as source veto_if_no_doors.
function shapes.round_box(builder, center_x, center_y, radius,
    wall, floor, door_count)
    local doors = door_count and round_doors(builder,
        center_x, center_y, radius, door_count) or {}

    if door_count and #doors == 0 then
        return false
    end

    local door_cells = {}

    for _, door in ipairs(doors) do
        door_cells[door.dy * (radius * 2 + 1) + door.dx] = true
    end

    for dy = -radius, radius do
        for dx = -radius, radius do
            local kind = round_kind(dx, dy, radius)

            if kind then
                local key = dy * (radius * 2 + 1) + dx
                local glyph = door_cells[key] and "+" or
                    (kind == "floor" and floor or wall)

                shapes.box(builder, center_x + dx, center_y + dy,
                    center_x + dx, center_y + dy, glyph)
            end
        end
    end

    return true
end

-- A source connector rejects a straight wall strip if it already contains
-- another opening between parallel floor strips. This avoids rows of doors
-- in the same narrow band.
local function wall_strip_clear(builder, x, y, horizontal)
    for _, sign in ipairs({ -1, 1 }) do
        local distance = 1

        while true do
            local px = x + (horizontal and sign * distance or 0)
            local py = y + (horizontal and 0 or sign * distance)
            local side_x = horizontal and 0 or 1
            local side_y = horizontal and 1 or 0

            if px <= 0 or px >= builder.width - 1 or
                py <= 0 or py >= builder.height - 1 or
                builder:cell(px + side_x, py + side_y) ~= "." or
                builder:cell(px - side_x, py - side_y) ~= "." then
                break
            end

            if builder:cell(px, py) ~= "X" then
                return false
            end

            distance = distance + 1
        end
    end

    return true
end

-- Connect nearby passages through a one-cell reserved wall. A random
-- nonrepeating scan checks at most the source's 2,000 candidate cells.
function shapes.connect_adjacent(builder, attempts)
    local candidates = {}
    local connected = 0

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            candidates[#candidates + 1] = {
                x = x,
                y = y,
            }
        end
    end

    for _ = 1, math.min(attempts, #candidates) do
        local index = builder:roll(#candidates) + 1
        local point = candidates[index]

        candidates[index] = candidates[#candidates]
        candidates[#candidates] = nil

        local x = point.x
        local y = point.y

        if builder:cell(x, y) == "X" then
            local vertical = builder:cell(x, y - 1) == "." and
                builder:cell(x, y + 1) == "." and
                wall_strip_clear(builder, x, y, true)
            local horizontal = builder:cell(x - 1, y) == "." and
                builder:cell(x + 1, y) == "." and
                wall_strip_clear(builder, x, y, false)

            if vertical or horizontal then
                builder:set(x, y, ".")
                connected = connected + 1
            end
        end
    end

    return connected
end

return shapes
