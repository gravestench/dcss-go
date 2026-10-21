-- Theory of operation: source delve grows floor from a frontier of diggable
-- wall cells. A candidate must see the requested number of open neighbors;
-- the connection chance decides whether it may join separate passages.
-- Pulling from the newest few frontier cells creates winding tunnels,
-- while a large top value spreads branches across the whole frontier.
local delve = {}

-- Keep coordinate construction explicit without repeating inline tables at
-- every frontier push and compass declaration.
local function coordinate(x, y)
    return {
        x = x,
        y = y,
    }
end

local compass = {
    coordinate(0, -1),
    coordinate(1, -1),
    coordinate(1, 0),
    coordinate(1, 1),
    coordinate(0, 1),
    coordinate(-1, 1),
    coordinate(-1, 0),
    coordinate(-1, -1),
}

local estimate_denominator = {
    [2] = 8,
    [3] = 7,
    [4] = 6,
    [5] = 5,
    [6] = 5,
    [7] = 4,
    [8] = 4,
    [9] = 4,
    [10] = 3,
    [11] = 3,
}

-- The source's temporary x/X alphabet keeps reserved cells from being dug.
-- The grid owner never exposes these markers after a layout finishes.
function delve.prepare(builder)
    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, "x")
        end
    end
end

-- Convert both temporary wall classes into the terrain codec's rock glyph.
function delve.finish(builder)
    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "x" or glyph == "X" then
                builder:set(x, y, "#")
            end
        end
    end
end

-- Source minimum_map_area.NARROW_CAVES requires floor or stair glyphs on
-- more than ten percent of the full map. The same check validates both
-- authored delve variants that declare a DES validate hook.
function delve.has_minimum_area(result)
    local builder = result.builder
    local floor = 0

    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyph == "{" or glyph == "}" or
                glyph == "(" or glyph == ")" or
                glyph == "[" or glyph == "]" or
                glyph == "<" or glyph == ">" then
                floor = floor + 1
            end
        end
    end

    return floor > builder.width * builder.height * 0.1
end

-- Source zonify joins floor diagonally as well as cardinally. Keep its
-- largest connected region after a cross or circle is built and seal the
-- others before the catalog places stairs.
function delve.keep_largest_region(builder)
    local visited = {}
    local regions = {}
    local largest = {}

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            local key = y * builder.width + x
            local glyph = builder:cell(x, y)

            if not visited[key] and
                (glyph == "." or glyph == "{" or glyph == "+") then
                local cells = { coordinate(x, y) }
                local first = 1

                visited[key] = true

                while first <= #cells do
                    local current = cells[first]

                    first = first + 1

                    for _, direction in ipairs(compass) do
                        local nx = current.x + direction.x
                        local ny = current.y + direction.y
                        local neighbor = ny * builder.width + nx
                        local next_glyph = builder:cell(nx, ny)

                        if not visited[neighbor] and
                            (next_glyph == "." or next_glyph == "{" or
                            next_glyph == "+") then
                            visited[neighbor] = true
                            cells[#cells + 1] = coordinate(nx, ny)
                        end
                    end
                end

                regions[#regions + 1] = cells

                if #cells > #largest then
                    largest = cells
                end
            end
        end
    end

    for _, cells in ipairs(regions) do
        if cells ~= largest then
            for _, cell in ipairs(cells) do
                builder:set(cell.x, cell.y, "#")
            end
        end
    end

    return #largest
end

-- Count all eight traversable neighbors, including diagonal contacts, as
-- the source dgn-delve.cc does. Stairs and reserved main-route markers are
-- also open for the next carved cell.
local function open(glyph)
    return glyph == "." or glyph == "@" or glyph == ">" or
        glyph == "<" or glyph == "{" or glyph == "}"
end

-- Count open neighbors and the distinct groups they form around one wall.
-- The group count prevents accidental shortcuts unless a layout requests
-- a nonzero connection chance.
local function neighbors(builder, x, y)
    local count = 0
    local groups = 0
    local first = compass[1]
    local previous = open(builder:cell(x + first.x, y + first.y))
    local before_previous = false

    for _, offset in ipairs(compass) do
        local current = open(builder:cell(x + offset.x, y + offset.y))

        if current then
            count = count + 1
        end
    end

    -- The source counts diagonal contacts as joined only when their
    -- intervening cardinal neighbor is also open. Scan in reverse around
    -- the eight-cell ring to retain that rule at the wraparound point.
    for index = #compass, 1, -1 do
        local offset = compass[index]
        local current = open(builder:cell(x + offset.x, y + offset.y))

        if current and not previous and
            (index % 2 == 0 or not before_previous) then
            groups = groups + 1
        end

        before_previous = previous
        previous = current
    end

    if previous and groups == 0 then
        groups = 1
    end

    return count, groups
end

-- A fresh run can start beside existing floor or at the center of its
-- diggable area. Retrying after a stuck frontier uses the same rule.
local function seed(builder, store)
    local count = 0
    local total_x = 0
    local total_y = 0

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "x" then
                count = count + 1
                total_x = total_x + x
                total_y = total_y + y

                local adjacent = neighbors(builder, x, y)

                if adjacent > 0 then
                    store[#store + 1] = coordinate(x, y)
                end
            end
        end
    end

    if #store > 0 or count == 0 then
        return count
    end

    local center_x = total_x / count
    local center_y = total_y / count
    local best
    local distance = math.huge

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "x" then
                local delta = math.max(math.abs(x - center_x),
                    math.abs(y - center_y))

                if delta < distance then
                    best = coordinate(x, y)
                    distance = delta
                end
            end
        end
    end

    store[#store + 1] = best

    return count
end

-- Source _rndpull chooses within the newest `top` cells and removes that
-- entry without swapping its position, preserving the tunnel bias.
local function pull(builder, store, top)
    if #store == 0 then
        return nil
    end

    local window = math.min(top, #store)
    local index = #store - builder:roll(window)

    return table.remove(store, index)
end

-- Shuffle eight directions per new floor cell. The source allows duplicate
-- frontier entries; a later pull simply skips a cell already dug.
local function dig(builder, store, point)
    builder:set(point.x, point.y, ".")

    local order = { 1, 2, 3, 4, 5, 6, 7, 8 }

    for last = 8, 1, -1 do
        local choice = builder:roll(last) + 1
        local offset = compass[order[choice]]

        order[choice] = order[last]

        local x = point.x + offset.x
        local y = point.y + offset.y

        if builder:cell(x, y) == "x" then
            store[#store + 1] = coordinate(x, y)
        end
    end
end

-- Carve at most `cell_count` new cells. A negative count means the source
-- estimate derived from available wall area and neighbor thresholds.
function delve.carve(builder, minimum, maximum, connection_chance,
    cell_count, top)
    local store = {}
    local world = seed(builder, store)
    local target = cell_count

    if target < 0 then
        target = math.floor(world /
            estimate_denominator[minimum + maximum])
    end

    target = math.min(target, world)

    local dug = 0
    local retries = 0

    while dug < target and retries <= 50 do
        local center = pull(builder, store, math.max(1, #store))

        if not center then
            break
        end

        store[#store + 1] = center

        -- Grow a tiny seed without the minimum neighbor requirement. This
        -- gives a fresh frontier enough floor to enter the normal loop.
        local minimum_seed = dug + 2 * minimum

        while dug < minimum_seed and dug < target do
            local point = pull(builder, store, top)

            if not point then
                break
            end

            if builder:cell(point.x, point.y) == "x" then
                local count, groups = neighbors(builder, point.x, point.y)
                local close = math.max(math.abs(point.x - center.x),
                    math.abs(point.y - center.y)) <= 2

                if close and count <= maximum and
                    (groups <= 1 or builder:chance_in(connection_chance, 100)) then
                    dig(builder, store, point)
                    dug = dug + 1
                end
            end
        end

        while dug < target do
            local point = pull(builder, store, top)

            if not point then
                break
            end

            if builder:cell(point.x, point.y) == "x" then
                local count, groups = neighbors(builder, point.x, point.y)

                if count >= minimum and count <= maximum and
                    (groups <= 1 or builder:chance_in(connection_chance, 100)) then
                    dig(builder, store, point)
                    dug = dug + 1
                end
            end
        end

        if dug < target then
            retries = retries + 1
            seed(builder, store)
        end
    end

    return dug
end

return delve
