-- Example: Two stair coordinates enter the flood-visit set before corridor connection.
local grid = require("policy.generation.grid")
local trail = require("policy.generation.trail")
local corridors = require("policy.generation.corridors")
local rooms = require("policy.generation.rooms")
local branches = require("ids.branches")

local basic = {}

local starts = {
    { x = 35, width = 30, y = 35, height = 20 },
    { x = 10, width = 15, y = 10, height = 15 },
    { x = 50, width = 20, y = 10, height = 15 },
}

-- Encode stair coordinates for overlap and flood-visit sets.
local function key(point)
    return point.x .. ":" .. point.y
end

-- Flood from the first down stair to reject layouts with any unreachable up or down stair.
local function connected(builder, stairs)
    local start = stairs[1].down
    local visited = {
        [key(start)] = true,
    }
    local queue = { start }
    local first = 1

    while first <= #queue do
        local current = queue[first]
        first = first + 1

        for _, direction in ipairs(trail.cardinal) do
            local next_cell = {
                x = current.x + direction.x,
                y = current.y + direction.y,
            }
            local id = key(next_cell)

            if builder:inside(next_cell) and not visited[id] and
                builder:cell(next_cell.x, next_cell.y) ~= "#" then
                visited[id] = true
                queue[#queue + 1] = next_cell
            end
        end
    end

    for _, pair in ipairs(stairs) do
        if not visited[key(pair.down)] or not visited[key(pair.up)] then
            return false
        end
    end

    return true
end

-- Draw three stair trails first, then connect their down stairs and add rooms around that backbone.
local function build(builder, depth)
    -- Corridor length is drawn before count and intersection behavior for this layout attempt.
    builder.corr_length = 2 + builder:roll(14)

    if builder:one_in(100) then
        builder.corr_count = 500 + builder:roll(500)
    else
        builder.corr_count = 30 + builder:roll(200)
    end

    if builder:one_in(20) then
        builder.intersect_in = 400
    else
        builder.intersect_in = builder:roll(20)
    end

    local stairs = {}
    local occupied = {}

    for index, start in ipairs(starts) do
        local pair, err = trail.make(builder, start)

        if not pair then
            return nil, string.format("Dungeon:%d trail %d: %s", depth, index, err)
        end

        local down_key = key(pair.down)
        local up_key = key(pair.up)

        -- Reject overlapping stair trails before corridors can make the overlap appear connected.
        if occupied[down_key] or occupied[up_key] or down_key == up_key then
            return nil, string.format("Dungeon:%d trail %d overlaps another stair", depth, index)
        end

        occupied[down_key] = true
        occupied[up_key] = true
        stairs[index] = pair
        builder:set(pair.down.x, pair.down.y, ">")
        builder:set(pair.up.x, pair.up.y, "<")
    end

    for first = 1, #stairs do
        for second = first + 1, #stairs do
            corridors.connect(builder, stairs[first].down, stairs[second].down)
        end
    end

    rooms.make(builder)
    builder:one_in(5 + depth - 1)

    -- Connectivity is checked after rooms and corridors have changed the final grid.
    if not connected(builder, stairs) then
        return nil, string.format("Dungeon:%d basic layout has disconnected stairs", depth)
    end

    return stairs, nil
end

-- Retry rejected layouts until each floor has a connected stair backbone.
function basic.generate(ctx, depth)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth

    if depth < 1 or depth > bottom then
        error("basic Dungeon layout needs a valid depth and a random source")
    end

    local last_error

    for _ = 1, 16 do
        local builder = grid.new(ctx)
        local stairs, err = build(builder, depth)

        if builder.bad_random then
            error("random source failed to provide a bounded draw")
        end

        if stairs then
            return {
                rows = builder:rows(),
                stairs = stairs,
                builder = builder,
            }
        end

        last_error = err
    end

    error(string.format("Dungeon:%d layout failed after 16 attempts: %s", depth, last_error))
end

return basic
