-- Source add_pools seeds several floor regions, expands them in random
-- frontier order, and leaves paths where two different pools would touch.
-- The policy operates on glyphs so Dungeon and Depths choose their contents.
local grid = require("policy.generation.grid")

local pools = {}

local unassigned = -1
local open = -2
local border = -3
local forbidden = -4

local cardinal = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

local adjacent = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
    { x = 1, y = 1 },
    { x = -1, y = 1 },
    { x = 1, y = -1 },
    { x = -1, y = -1 },
}

-- Use zero-based coordinates against Lua's one-based arrays in only these
-- two functions, keeping pool propagation readable below.
local function get(states, x, y)
    if x < 0 or x >= grid.width or y < 0 or y >= grid.height then
        return forbidden
    end

    return states[y + 1][x + 1]
end

-- Keep all pool state changes in the same matrix used by the frontier.
local function set(states, x, y, value)
    states[y + 1][x + 1] = value
end

-- Mark only ordinary floor as a potential pool. Walls and other features
-- remain forbidden, so the pool pass cannot swallow a pre-existing stair.
local function initial_states(builder)
    local states = {}
    local floor = {}

    for y = 0, grid.height - 1 do
        states[y + 1] = {}

        for x = 0, grid.width - 1 do
            if builder:cell(x, y) == "." then
                set(states, x, y, unassigned)
                floor[#floor + 1] = { x = x, y = y }
            else
                set(states, x, y, forbidden)
            end
        end
    end

    return states, floor
end

-- Source seed placement draws up to floor-area/pool-size points, rejecting
-- candidates closer than the requested squared separation.
local function choose_seeds(builder, floor, pool_size)
    local goal = math.floor((#floor + builder:roll(pool_size)) / pool_size)
    local seeds = {}

    for _ = 1, goal do
        if #floor == 0 then
            break
        end

        local index = builder:roll(#floor) + 1
        local point = floor[index]

        floor[index] = floor[#floor]
        floor[#floor] = nil

        local close = false

        for _, prior in ipairs(seeds) do
            local dx = point.x - prior.x
            local dy = point.y - prior.y

            if dx * dx + dy * dy < 4 then
                close = true
                break
            end
        end

        if not close then
            seeds[#seeds + 1] = point
        end
    end

    return seeds
end

-- Seed frontiers also include adjacent wall cells, as in the source. Later
-- growth adds only unassigned floor so pools cannot tunnel through rock.
local function enqueue(states, frontier, point, first_ring)
    for _, offset in ipairs(cardinal) do
        local x = point.x + offset.x
        local y = point.y + offset.y

        local state = get(states, x, y)

        if state == unassigned or (first_ring and state == forbidden and
            x >= 0 and x < grid.width and y >= 0 and y < grid.height) then
            set(states, x, y, open)
            frontier[#frontier + 1] = { x = x, y = y }
        end
    end
end

-- A frontier cell touching two pool IDs or a forbidden wall becomes a
-- border path; otherwise it joins the one neighboring pool.
local function neighbor_owner(states, point)
    local owner

    for _, offset in ipairs(adjacent) do
        local value = get(states, point.x + offset.x, point.y + offset.y)

        if value == forbidden then
            return border
        elseif value > 0 then
            if owner and owner ~= value then
                return border
            end

            owner = value
        end
    end

    return owner or unassigned
end

-- Expand seeds through the candidate floor, drawing a random frontier
-- element each time and preserving one-cell separation between pools.
local function grow(builder, states, seeds)
    local frontier = {}

    for index, point in ipairs(seeds) do
        set(states, point.x, point.y, index)
    end

    for _, point in ipairs(seeds) do
        enqueue(states, frontier, point, true)
    end

    while #frontier > 0 do
        local index = builder:roll(#frontier) + 1
        local point = frontier[index]

        frontier[index] = frontier[#frontier]
        frontier[#frontier] = nil

        local owner = neighbor_owner(states, point)

        set(states, point.x, point.y, owner)

        if owner ~= unassigned then
            enqueue(states, frontier, point)
        end
    end
end

-- Draw one material for each pool before painting cells. The caller passes
-- an ordered list so Lua table traversal cannot alter a seed's result.
local function choose_contents(builder, count, contents)
    local selected = {}
    local total = 0

    for _, entry in ipairs(contents) do
        total = total + math.max(0, math.floor(entry.weight))
    end

    if total == 0 then
        error("pool layout has no weighted contents")
    end

    for index = 1, count do
        local draw = builder:roll(total)

        for _, entry in ipairs(contents) do
            local weight = math.max(0, math.floor(entry.weight))

            if draw < weight then
                selected[index] = entry.glyph
                break
            end

            draw = draw - weight
        end
    end

    return selected
end

-- Paint the source result: assigned IDs use pool contents, while untouched
-- floor and borders remain floor and forbidden cells retain their glyph.
local function paint(builder, states, contents)
    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local owner = get(states, x, y)

            if owner > 0 then
                builder:set(x, y, contents[owner])
            elseif owner == unassigned or owner == border then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Grow all source pools on one builder and return the seed count for tests
-- or future generation diagnostics.
function pools.add(builder, pool_size, contents)
    local states, floor = initial_states(builder)
    local seeds = choose_seeds(builder, floor, pool_size)
    local selected = choose_contents(builder, #seeds, contents)

    grow(builder, states, seeds)
    paint(builder, states, selected)

    return #seeds
end

return pools
