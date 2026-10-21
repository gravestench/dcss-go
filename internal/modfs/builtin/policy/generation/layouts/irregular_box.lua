-- Theory of operation: the source irregular-box builder divides each of
-- four walls into short orthogonal runs, varies their inward distance, then
-- flood-fills the enclosed floor. It builds off-map first so crossing walls
-- cannot corrupt an existing city when a shape must be regenerated.
local grid = require("policy.generation.grid")

local box = {}

local minimum_size = 5
local minimum_separation = 2
local maximum_attempts = 128
local outside = "outside"

-- Keep every room inside the playable grid. The C++ builder enforces the
-- same bounds before allocating its temporary wall matrix.
local function dimensions(builder, options)
    local x1 = math.max(0, math.floor(options.x1))
    local y1 = math.max(0, math.floor(options.y1))
    local x2 = math.min(builder.width - 1, math.floor(options.x2))
    local y2 = math.min(builder.height - 1, math.floor(options.y2))

    return {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        width = x2 - x1 + 1,
        height = y2 - y1 + 1,
    }
end

-- A too-small room cannot hold divided walls. Draw the source's simple
-- hollow-box fallback and choose doors from all perimeter cells.
local function simple(builder, bounds, options)
    local walls = {}
    local wall = options.wall or "#"
    local floor = options.floor or "."

    for x = bounds.x1, bounds.x2 do
        walls[#walls + 1] = { x = x, y = bounds.y1 }
        walls[#walls + 1] = { x = x, y = bounds.y2 }
    end

    for y = bounds.y1 + 1, bounds.y2 - 1 do
        walls[#walls + 1] = { x = bounds.x1, y = y }
        walls[#walls + 1] = { x = bounds.x2, y = y }
    end

    for y = bounds.y1, bounds.y2 do
        for x = bounds.x1, bounds.x2 do
            local boundary = x == bounds.x1 or x == bounds.x2 or
                y == bounds.y1 or y == bounds.y2

            builder:set(x, y, boundary and wall or floor)
        end
    end

    for _ = 1, math.min(options.doors or 1, #walls) do
        local index = builder:roll(#walls) + 1
        local point = walls[index]

        builder:set(point.x, point.y, "+")
        walls[index] = walls[#walls]
        walls[#walls] = nil
    end
end

-- The source repeatedly redraws a corner offset until opposite offsets
-- leave a central room wide enough to avoid wall self-intersections.
local function separate(builder, first, second, size)
    if size <= 0 then
        return first, second
    end

    while first + second >= size do
        if builder:one_in(2) then
            first = builder:roll(first)
        else
            second = builder:roll(second)
        end
    end

    return first, second
end

-- Pick up to the requested number of divisions, with at least two cells
-- between each pair. The initial end points always remain in the list.
local function divisions(builder, first, last, maximum)
    local values = { first, last }

    for _ = 1, maximum do
        local chosen = first + builder:roll(last - first + 1)

        for index = 1, #values - 1 do
            if chosen >= values[index] + minimum_separation and
                chosen <= values[index + 1] - minimum_separation then
                table.insert(values, index + 1, chosen)
                break
            end
        end
    end

    return values
end

-- Draw the inset of each straight run. One run is forced to touch the
-- requested outer bounds so the box actually occupies its advertised area.
local function distances(builder, first, last, maximum, count)
    local values = {}
    local length = math.max(1, count)

    values[1] = first

    for index = 2, length do
        values[index] = builder:roll(maximum)
    end

    values[length] = last
    values[builder:roll(length) + 1] = 0

    return values
end

-- A corner starts as four independent offsets. Adjusting each opposing
-- pair prevents top/bottom or left/right insets from crossing each other.
local function corners(builder, width, height, inset_x, inset_y)
    local top_left = {
        x = builder:roll(inset_x),
        y = builder:roll(inset_y),
    }
    local top_right = {
        x = builder:roll(inset_x),
        y = builder:roll(inset_y),
    }
    local bottom_left = {
        x = builder:roll(inset_x),
        y = builder:roll(inset_y),
    }
    local bottom_right = {
        x = builder:roll(inset_x),
        y = builder:roll(inset_y),
    }

    top_left.x, top_right.x = separate(builder,
        top_left.x, top_right.x, width - minimum_size)
    bottom_left.x, bottom_right.x = separate(builder,
        bottom_left.x, bottom_right.x, width - minimum_size)
    top_left.y, bottom_left.y = separate(builder,
        top_left.y, bottom_left.y, height - minimum_size)
    top_right.y, bottom_right.y = separate(builder,
        top_right.y, bottom_right.y, height - minimum_size)

    return top_left, top_right, bottom_left, bottom_right
end

-- A local x/y matrix holds only this candidate box. Source outside cells
-- remain nil until the interior and exterior fills decide their role.
local function matrix(width)
    local cells = {}

    for x = 0, width - 1 do
        cells[x] = {}
    end

    return cells
end

-- Record a wall candidate unless it is a run corner. Doors on straight
-- cells cannot sever two perpendicular wall segments at once.
local function mark(cells, candidates, x, y, glyph, door_candidate)
    cells[x][y] = glyph

    if door_candidate then
        candidates[#candidates + 1] = { x = x, y = y }
    end
end

-- Draw one horizontal wall's runs and the short vertical connectors at
-- division boundaries. Reverse maps bottom insets back into local y.
local function horizontal(cells, candidates, divisions_x, insets,
    height, reverse, wall)
    for index, inset in ipairs(insets) do
        local y = reverse and height - 1 - inset or inset

        if index > 1 then
            local previous = reverse and height - 1 - insets[index - 1] or
                insets[index - 1]
            local low = math.min(y, previous)
            local high = math.max(y, previous)

            for connector = low + 1, high - 1 do
                mark(cells, candidates, divisions_x[index], connector,
                    wall, true)
            end
        end

        for x = divisions_x[index], divisions_x[index + 1] do
            local interior = x > divisions_x[index] and
                x < divisions_x[index + 1]

            mark(cells, candidates, x, y, wall, interior)
        end
    end
end

-- Draw one vertical side using the same source division contract, now
-- reflecting right-side distances across the local x span.
local function vertical(cells, candidates, divisions_y, insets,
    width, reverse, wall)
    for index, inset in ipairs(insets) do
        local x = reverse and width - 1 - inset or inset

        if index > 1 then
            local previous = reverse and width - 1 - insets[index - 1] or
                insets[index - 1]
            local low = math.min(x, previous)
            local high = math.max(x, previous)

            for connector = low + 1, high - 1 do
                mark(cells, candidates, connector, divisions_y[index],
                    wall, true)
            end
        end

        for y = divisions_y[index], divisions_y[index + 1] do
            local interior = y > divisions_y[index] and
                y < divisions_y[index + 1]

            mark(cells, candidates, x, y, wall, interior)
        end
    end
end

-- Doors are drawn before filling. Their glyph blocks the interior flood
-- exactly like wall, but remains a traversable opening in the final map.
local function doors(builder, cells, candidates, count)
    for _ = 1, math.min(count, #candidates) do
        local index = builder:roll(#candidates) + 1
        local point = candidates[index]

        cells[point.x][point.y] = "+"
        candidates[index] = candidates[#candidates]
        candidates[#candidates] = nil
    end
end

-- Flood from inside the north-west corner. Only unset cells can become
-- floor, so a malformed crossing leaves an unset pocket to detect later.
local function flood(cells, start_x, start_y, width, height, fill)
    if start_x < 0 or start_x >= width or
        start_y < 0 or start_y >= height or cells[start_x][start_y] then
        return
    end

    local queue = { { x = start_x, y = start_y } }
    local head = 1

    cells[start_x][start_y] = fill

    while head <= #queue do
        local point = queue[head]
        head = head + 1

        local neighbors = {
            { x = point.x + 1, y = point.y },
            { x = point.x - 1, y = point.y },
            { x = point.x, y = point.y + 1 },
            { x = point.x, y = point.y - 1 },
        }

        for _, next_point in ipairs(neighbors) do
            if next_point.x >= 0 and next_point.x < width and
                next_point.y >= 0 and next_point.y < height and
                not cells[next_point.x][next_point.y] then
                cells[next_point.x][next_point.y] = fill
                queue[#queue + 1] = next_point
            end
        end
    end
end

-- Fill every exterior edge pocket. Nil remaining afterward means the
-- orthogonal walls enclosed more than one interior and must be redrawn.
local function valid_interior(cells, width, height, floor)
    for x = 0, width - 1 do
        flood(cells, x, 0, width, height, outside)
        flood(cells, x, height - 1, width, height, outside)
    end

    for y = 0, height - 1 do
        flood(cells, 0, y, width, height, outside)
        flood(cells, width - 1, y, width, height, outside)
    end

    local floor_count = 0

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if cells[x][y] == nil then
                return false
            elseif cells[x][y] == floor then
                floor_count = floor_count + 1
            end
        end
    end

    return floor_count > 0
end

-- Assemble one source candidate, including corner reconnection after a
-- forced zero inset changes the shared wall endpoint.
local function candidate(builder, bounds, options, inset_x, inset_y)
    local width = bounds.width
    local height = bounds.height
    local top_left, top_right, bottom_left, bottom_right =
        corners(builder, width, height, inset_x, inset_y)
    local top = divisions(builder, top_left.x,
        width - 1 - top_right.x, options.div_x or 1)
    local bottom = divisions(builder, bottom_left.x,
        width - 1 - bottom_right.x, options.div_x or 1)
    local left = divisions(builder, top_left.y,
        height - 1 - bottom_left.y, options.div_y or 1)
    local right = divisions(builder, top_right.y,
        height - 1 - bottom_right.y, options.div_y or 1)
    local top_insets = distances(builder, top_left.y,
        top_right.y, inset_y, #top - 1)
    local bottom_insets = distances(builder, bottom_left.y,
        bottom_right.y, inset_y, #bottom - 1)
    local left_insets = distances(builder, top_left.x,
        bottom_left.x, inset_x, #left - 1)
    local right_insets = distances(builder, top_right.x,
        bottom_right.x, inset_x, #right - 1)

    top[1] = left_insets[1]
    top[#top] = width - 1 - right_insets[1]
    bottom[1] = left_insets[#left_insets]
    bottom[#bottom] = width - 1 - right_insets[#right_insets]
    left[1] = top_insets[1]
    left[#left] = height - 1 - bottom_insets[1]
    right[1] = top_insets[#top_insets]
    right[#right] = height - 1 - bottom_insets[#bottom_insets]

    local cells = matrix(width)
    local wall_cells = {}
    local wall = options.wall or "#"
    local floor = options.floor or "."

    horizontal(cells, wall_cells, top, top_insets, height, false, wall)
    horizontal(cells, wall_cells, bottom, bottom_insets, height, true, wall)
    vertical(cells, wall_cells, left, left_insets, width, false, wall)
    vertical(cells, wall_cells, right, right_insets, width, true, wall)
    doors(builder, cells, wall_cells, options.doors or 1)
    flood(cells, left_insets[1] + 1, top_insets[1] + 1,
        width, height, floor)

    if not valid_interior(cells, width, height, floor) then
        return nil
    end

    return cells
end

-- Copy only the interior and wall cells. Nil exterior in the source does
-- not erase streets or earlier rooms under the candidate bounding box.
local function copy(builder, bounds, cells)
    for x = 0, bounds.width - 1 do
        for y = 0, bounds.height - 1 do
            local glyph = cells[x][y]

            if glyph ~= outside then
                builder:set(bounds.x1 + x, bounds.y1 + y, glyph)
            end
        end
    end
end

-- Build one irregular source room. A finite regeneration bound turns a
-- malformed source-like shape into a clear generation error, not a quiet
-- rectangular substitution that could make a bad layout look successful.
function box.carve(builder, options)
    local bounds = dimensions(builder, options)

    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    if bounds.width < minimum_size or bounds.height < minimum_size then
        simple(builder, bounds, options)
        return
    end

    local inset_x = math.max(0, math.min(
        math.floor(options.in_x or 10000),
        math.floor((bounds.width - 1) / 2) - 1))
    local inset_y = math.max(0, math.min(
        math.floor(options.in_y or 10000),
        math.floor((bounds.height - 1) / 2) - 1))

    for _ = 1, maximum_attempts do
        local cells = candidate(builder, bounds, options, inset_x, inset_y)

        if cells then
            copy(builder, bounds, cells)
            return
        end
    end

    error("irregular box could not form one enclosed interior")
end

return box
