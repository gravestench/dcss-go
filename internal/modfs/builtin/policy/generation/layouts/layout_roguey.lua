-- Theory of operation: the source Roguey layout arranges three to five rows
-- and columns of irregular small rooms. Some slots are absent; neighbors
-- connect across those gaps with bent corridors. Rare rooms contain a maze
-- or an inner walled chamber. The shared stair postpass uses its open floor.
local grid = require("policy.generation.grid")

local layout = {}

local directions = {
    { x = 2, y = 0 },
    { x = -2, y = 0 },
    { x = 0, y = 2 },
    { x = 0, y = -2 },
}

-- DCSS random_range includes both endpoints. All room and door dimensions
-- use that convention, unlike the zero-based builder roll itself.
local function range(builder, first, last)
    return first + builder:roll(last - first + 1)
end

-- The source favors a five-by-five grid, with three-by-three quite rare.
local function grid_count(builder)
    local draw = builder:roll(16)

    if draw < 10 then
        return 5
    elseif draw < 15 then
        return 4
    end

    return 3
end

-- Carve every cell of an ordinary room, including its former outer rock.
-- Doors are placed only when the connecting corridor is chosen later.
local function fill_room(builder, room)
    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            builder:set(x, y, room.fill)
        end
    end
end

-- Miniature mazes use depth-first growth in two-cell steps, leaving a wall
-- between paths until the connecting step is carved.
local function maze_neighbors(builder, room, point)
    local choices = {}

    for _, direction in ipairs(directions) do
        local x = point.x + direction.x
        local y = point.y + direction.y

        if x >= room.x1 and x <= room.x2 and
            y >= room.y1 and y <= room.y2 and
            builder:cell(x, y) ~= "." then
            choices[#choices + 1] = { x = x, y = y }
        end
    end

    return choices
end

-- An explicit stack preserves the source's recursive maze walk without
-- making a large room's path depend on Lua recursion depth.
local function make_maze(builder, room)
    local half_x = math.floor((room.x2 - room.x1) / 2)
    local half_y = math.floor((room.y2 - room.y1) / 2)
    local start = {
        x = room.x1 + 2 * builder:roll(half_x),
        y = room.y1 + 2 * builder:roll(half_y),
    }
    local stack = { start }

    builder:set(start.x, start.y, ".")

    while #stack > 0 do
        local point = stack[#stack]
        local choices = maze_neighbors(builder, room, point)

        if #choices == 0 then
            stack[#stack] = nil
        else
            local next_point = choices[builder:roll(#choices) + 1]
            local middle_x = math.floor((point.x + next_point.x) / 2)
            local middle_y = math.floor((point.y + next_point.y) / 2)

            builder:set(middle_x, middle_y, ".")
            builder:set(next_point.x, next_point.y, ".")
            stack[#stack + 1] = next_point
        end
    end
end

-- A rare inner chamber has a second wall ring and one door. It should not
-- replace its outer room's corridor entrances.
local function inner_chamber(builder, room)
    local walls = { "v", "v", "c", "c", "c", "#", "#", "#" }
    local wall = walls[builder:roll(#walls) + 1]
    local left = room.x1 + 1
    local right = room.x2 - 1
    local top = room.y1 + 1
    local bottom = room.y2 - 1

    for y = top, bottom do
        for x = left, right do
            if x == left or x == right or y == top or y == bottom then
                builder:set(x, y, wall)
            end
        end
    end

    local side = builder:roll(4)

    if side < 2 then
        local x = side == 0 and left or right
        builder:set(x, range(builder, top + 1, bottom - 1), "+")
    else
        local y = side == 2 and top or bottom
        builder:set(range(builder, left + 1, right - 1), y, "+")
    end
end

-- The source builds room bounds from grid spacing, then independently
-- decides presence, maze rarity, and whether corridor endpoints are doors.
local function make_room(builder, column, row, columns, rows, depth)
    local xspace = 13 + 2 * (5 - columns)
    local yspace = 11 + 2 * (5 - rows)
    local xsize = 6 + 2 * (5 - columns)
    local ysize = 6 + 2 * (5 - rows)
    local base_x = column * xspace + 8
    local base_y = row * yspace + 8
    local room = {
        x1 = base_x + builder:roll(4),
        y1 = base_y + builder:roll(4),
        x2 = base_x + xsize + builder:roll(5),
        y2 = base_y + ysize + builder:roll(3),
        present = not builder:one_in(6),
        maze = builder:roll(10) < depth - 1 and builder:one_in(15),
        fill = ".",
        door = builder:one_in(3) and "." or "+",
    }

    if room.maze then
        if (room.x2 - room.x1) % 2 ~= 0 then
            room.x2 = room.x2 + 1
        end

        if (room.y2 - room.y1) % 2 ~= 0 then
            room.y2 = room.y2 + 1
        end
    end

    return room
end

-- A maze corridor must enter through a carved boundary cell. If a source
-- maze has no such edge, use the midpoint rather than retrying forever.
local function boundary_coordinate(builder, room, side)
    local horizontal = side == "top" or side == "bottom"
    local first = horizontal and room.x1 + 1 or room.y1 + 1
    local last = horizontal and room.x2 - 1 or room.y2 - 1
    local candidates = {}

    if room.maze then
        for value = first, last do
            local x = horizontal and value or (side == "left" and room.x1 or room.x2)
            local y = horizontal and (side == "top" and room.y1 or room.y2) or value

            if builder:cell(x, y) == "." then
                candidates[#candidates + 1] = value
            end
        end
    end

    if #candidates > 0 then
        return candidates[builder:roll(#candidates) + 1]
    end

    return range(builder, first, last)
end

-- Connect two edges by a path whose axis probability tracks the remaining
-- distance, mirroring the source's bent corridor rather than an L shape.
local function carve_link(builder, first, second)
    local x = first.x
    local y = first.y

    builder:set(x, y, ".")

    while x ~= second.x or y ~= second.y do
        local dx = math.abs(second.x - x)
        local dy = math.abs(second.y - y)

        if dx > 0 and (dy == 0 or builder:roll(dx + dy) < dx) then
            x = x + (x < second.x and 1 or -1)
        else
            y = y + (y < second.y and 1 or -1)
        end

        builder:set(x, y, ".")
    end
end

-- Preserve the source's endpoint doors when rooms are separated by at
-- least two cells; shorter gaps become a single open join.
local function link_rooms(builder, first, second, sideways)
    if not first.present or not second.present then
        return
    end

    local start
    local finish

    if sideways then
        local y1 = boundary_coordinate(builder, first, "right")
        local y2 = boundary_coordinate(builder, second, "left")

        start = { x = first.x2 + 1, y = y1 }
        finish = { x = second.x1 - 1, y = y2 }

        if finish.x - start.x >= 2 then
            builder:set(start.x, start.y, first.door)
            builder:set(finish.x, finish.y, second.door)
            start.x = start.x + 1
            finish.x = finish.x - 1
        end
    else
        local x1 = boundary_coordinate(builder, first, "bottom")
        local x2 = boundary_coordinate(builder, second, "top")

        start = { x = x1, y = first.y2 + 1 }
        finish = { x = x2, y = second.y1 - 1 }

        if finish.y - start.y >= 2 then
            builder:set(start.x, start.y, first.door)
            builder:set(finish.x, finish.y, second.door)
            start.y = start.y + 1
            finish.y = finish.y - 1
        end
    end

    carve_link(builder, start, finish)
end

-- A missing slot does not sever the room graph: scan right and down until
-- the next present neighbor on the same source row or column.
local function join_grid(builder, rooms, columns, rows)
    for row = 1, rows do
        for column = 1, columns do
            local index = (row - 1) * columns + column
            local room = rooms[index]

            if room.present then
                for next_column = column + 1, columns do
                    local next_room = rooms[(row - 1) * columns + next_column]

                    if next_room.present then
                        link_rooms(builder, room, next_room, true)
                        break
                    end
                end

                for next_row = row + 1, rows do
                    local next_room = rooms[(next_row - 1) * columns + column]

                    if next_room.present then
                        link_rooms(builder, room, next_room, false)
                        break
                    end
                end
            end
        end
    end
end

-- Run the source room choices and return the same grid owner used by the
-- shared stair postpass. Special-room subvaults need their own catalog slice.
function layout.layout_roguey(api)
    local builder = grid.new(api.ctx)
    local rows = grid_count(builder)
    local columns = grid_count(builder)
    local rooms = {}

    for row = 0, rows - 1 do
        for column = 0, columns - 1 do
            rooms[#rooms + 1] = make_room(builder, column, row,
                columns, rows, api.depth)
        end
    end

    for _, room in ipairs(rooms) do
        if room.present then
            if room.maze then
                make_maze(builder, room)
            else
                fill_room(builder, room)

                if room.x2 - room.x1 > 5 and room.y2 - room.y1 > 5 and
                    (api.branch == "D" or api.branch == "Lair") and
                    builder:roll(450) < math.max(0, api.depth - 9) then
                    inner_chamber(builder, room)
                end
            end
        end
    end

    join_grid(builder, rooms, columns, rows)

    if builder.bad_random then
        error("Roguey layout random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        rooms = rooms,
    }
end

return layout
