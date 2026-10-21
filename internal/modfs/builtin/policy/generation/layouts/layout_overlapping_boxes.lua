-- Theory of operation: Dis overlapping boxes lays two hundred grid-aligned
-- rooms over one another. Shallow floors use smaller blocks; deeper floors
-- grow them. The source then opens walls between neighboring room floors
-- and removes disconnected pockets, leaving a compact room maze.
local grid = require("policy.generation.grid")
local rooms = require("policy.generation.layouts.dis_rooms")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Source depth_fraction is zero at branch entry and one at the bottom.
-- Dis's seventh floor is handled by its branch-end map, not this layout.
local function depth_fraction(api)
    if api.branch_bottom <= 1 then
        return 1
    end

    return (api.depth - 1) / (api.branch_bottom - 1)
end

-- Keep the source's inclusive block arithmetic. Adjacent boxes share
-- boundary cells, which is what gives this layout broad joined rooms.
local function place_boxes(builder, fraction)
    local block_size = math.floor(2 + fraction * 2 +
        builder:roll(1000000) * 3 / 1000000)
    local minimum = math.max(2,
        math.floor(8 + fraction * 2 - block_size))
    local maximum = math.floor(12 + fraction * 3 - block_size * 2)
    local across_x = math.floor((builder.width - 17) / block_size)
    local across_y = math.floor((builder.height - 17) / block_size)
    local start_x = math.floor(builder.width / 2) -
        math.floor(across_x * block_size / 2)
    local start_y = math.floor(builder.height / 2) -
        math.floor(across_y * block_size / 2)

    for _ = 1, 200 do
        local sum = subdivision.range(builder, minimum, maximum)
        local count_x = subdivision.range(builder, 1, sum - 1)
        local count_y = sum - count_x
        local block_x = subdivision.range(builder, 0, across_x - count_x)
        local block_y = subdivision.range(builder, 0, across_y - count_y)
        local x1 = start_x + block_x * block_size
        local y1 = start_y + block_y * block_size
        local x2 = x1 + count_x * block_size
        local y2 = y1 + count_y * block_size

        rooms.box(builder, x1, y1, x2, y2)
    end
end

-- Preserve the source DIVISIONS area gate after the connector and zone
-- cleanup. The catalog retries a new draw when a candidate is too small.
function layout.validate(result)
    return rooms.valid(result)
end

-- Run the complete source geometry through the named DES hook, so branch
-- choice and stair placement still belong to the production layout owner.
function layout.layout_overlapping_boxes(api)
    local builder = grid.new(api.ctx, api.width, api.height)

    place_boxes(builder, depth_fraction(api))
    rooms.connect(builder, 0, 1000)
    rooms.keep_largest(builder)

    if builder.bad_random then
        error("Dis boxes could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
    }
end

return layout
