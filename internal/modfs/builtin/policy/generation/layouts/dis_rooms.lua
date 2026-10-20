-- Theory of operation: the three Dis divisions layouts build rooms in an
-- otherwise solid rock grid. Shared geometry here handles inclusive source
-- rectangles, doors through one-cell dividing walls, and removal of floor
-- islands. The layouts decide where those operations happen.
local grid = require("policy.generation.grid")
local glyphs = require("constants.vault_glyphs")
local subdivision = require("policy.generation.layouts.subdivision")

local rooms = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- The source builder uses inclusive coordinates. Its x rock glyph is kept
-- distinct from ordinary # so the DES terrain decoder sees the source map.
function rooms.box(builder, x1, y1, x2, y2)
    for y = y1, y2 do
        for x = x1, x2 do
            local edge = x == x1 or x == x2 or y == y1 or y == y2

            builder:set(x, y, edge and "x" or ".")
        end
    end
end

-- The source walks each wall direction until the first corner. A corridor
-- irregularity before that corner vetoes an otherwise adjacent opening.
local function wall_clear(builder, x, y, wall, horizontal, distance)
    for _, step in ipairs({ -1, 1 }) do
        for offset = 1, distance do
            local line_x = x + (horizontal and step * offset or 0)
            local line_y = y + (horizontal and 0 or step * offset)
            local side_x = horizontal and 0 or 1
            local side_y = horizontal and 1 or 0

            if not builder:inside({ x = line_x + side_x, y = line_y + side_y }) or
                not builder:inside({ x = line_x - side_x, y = line_y - side_y }) or
                builder:cell(line_x + side_x, line_y + side_y) ~= "." or
                builder:cell(line_x - side_x, line_y - side_y) ~= "." then
                break
            end

            if builder:cell(line_x, line_y) ~= wall then
                return false
            end
        end
    end

    return true
end

-- A candidate wall separates two floor cells along one axis. The source
-- checks north/south first, then east/west if that direction cannot open.
local function door_candidate(builder, x, y, wall, check_distance)
    if not builder:inside({ x = x, y = y }) or
        builder:cell(x, y) ~= wall then
        return false
    end

    local north = builder:cell(x, y - 1) == "."
    local south = builder:cell(x, y + 1) == "."
    local east = builder:cell(x + 1, y) == "."
    local west = builder:cell(x - 1, y) == "."

    return (north and south and
            wall_clear(builder, x, y, wall, true, check_distance)) or
        (east and west and
            wall_clear(builder, x, y, wall, false, check_distance))
end

-- Sample each interior coordinate at most once, including floor and rock.
-- The source's min/max count limits checked points, not successful doors.
function rooms.connect(builder, minimum, maximum, wall, replacement,
    check_distance)
    wall = wall or "x"
    replacement = replacement or "+"
    check_distance = check_distance or grid.width

    local candidates = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            candidates[#candidates + 1] = { x = x, y = y }
        end
    end

    local attempts = math.min(#candidates,
        subdivision.range(builder, minimum, maximum))

    for _ = 1, attempts do
        local index = builder:roll(#candidates) + 1
        local point = candidates[index]

        candidates[index] = candidates[#candidates]
        candidates[#candidates] = nil

        if door_candidate(builder, point.x, point.y,
            wall, check_distance) then
            builder:set(point.x, point.y, replacement)
        end
    end
end

-- Doors and fountains belong to open regions, while statues remain solid.
-- The source zonify pass keeps its largest open zone and fills smaller
-- disconnected pockets with rock before stairs are chosen.
local function open(glyph)
    return glyph == "." or glyph == "+" or glyph == "V"
end

-- Flood one region, marking cells as soon as they enter the queue so the
-- same room is never counted twice through adjacent doors.
local function region(builder, start_x, start_y, visited)
    local cells = { { x = start_x, y = start_y } }
    local head = 1

    visited[start_y * grid.width + start_x] = true

    while head <= #cells do
        local point = cells[head]
        head = head + 1

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local key = y * grid.width + x

            if builder:inside({ x = x, y = y }) and
                not visited[key] and open(builder:cell(x, y)) then
                visited[key] = true
                cells[#cells + 1] = { x = x, y = y }
            end
        end
    end

    return cells
end

-- The largest region is the playable layout. Filling the others ensures
-- every stair can later be reached without changing the authored walls.
function rooms.keep_largest(builder)
    local visited = {}
    local largest = {}
    local regions = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local key = y * grid.width + x

            if not visited[key] and open(builder:cell(x, y)) then
                local cells = region(builder, x, y, visited)

                regions[#regions + 1] = cells

                if #cells > #largest then
                    largest = cells
                end
            end
        end
    end

    for _, cells in ipairs(regions) do
        if cells ~= largest then
            for _, point in ipairs(cells) do
                builder:set(point.x, point.y, "x")
            end
        end
    end

    return #largest
end

-- The source DIVISIONS validator requires more than fifteen percent of
-- the full builder area to be open. Its accepted glyph set includes stairs.
function rooms.valid(result)
    local count = 0
    local builder = result.builder

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyphs.up[glyph] or glyphs.down[glyph] then
                count = count + 1
            end
        end
    end

    return count > grid.width * grid.height * 0.15
end

return rooms
