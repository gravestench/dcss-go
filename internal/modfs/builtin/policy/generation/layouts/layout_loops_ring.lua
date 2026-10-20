-- Theory of operation: Ring begins with one large ragged annulus, grows
-- successively smaller loops around its recorded corners, then places small
-- rooms at intersections and unused medium-loop turns. The resulting
-- dungeon is corridor-heavy even when its ring is hard to see at a glance.
local grid = require("policy.generation.grid")
local paths = require("policy.generation.layouts.loop_paths")
local rooms = require("policy.generation.layouts.loop_rooms")
local cell_graph = require("policy.generation.layouts.cell_graph")

local layout = {}

-- Source radii and group counts derive from the smaller map dimension so
-- the same policy can fill a non-square builder without changing weights.
local function sizes(branch)
    local radius_max = branch == "Elf" and 5 or 4
    local small_border = 1 + radius_max
    local medium_border = small_border + 2
    local large_border = medium_border + 1
    local master_border = large_border + 3
    local smaller = math.min(grid.width, grid.height)
    local usable = smaller - 2 * small_border
    local area = usable * usable

    return {
        room_min = branch == "Elf" and 2 or 1,
        room_max = radius_max,
        room_corner_percent = branch == "Elf" and 20 or 10,
        master_min = math.floor(usable / 10),
        master_max = smaller / 2 - master_border,
        master_divisions = math.floor(usable / 12),
        large_count = math.floor(area / 1600),
        large_border = large_border,
        medium_count = math.floor(area / 1200),
        medium_border = medium_border,
        small_count = math.floor(area / 800),
        small_border = small_border,
    }
end

-- Run the named DES hook with source loop scales. Corner arrays remain
-- local to this one floor and do not depend on module load order.
function layout.layout_loops_ring(api)
    local builder = grid.new(api.ctx)
    local wall = paths.wall(builder, api)
    local size = sizes(api.branch)
    local master = {}
    local large = {}
    local medium = {}
    local small = {}

    paths.fill(builder, wall)
    paths.divided(builder, master, grid.width / 2, grid.height / 2,
        size.master_min, size.master_max, size.master_divisions)

    local count = 1

    count = count + paths.group(builder, large, master,
        size.large_count, 8, 20, size.large_border, 3)
    count = count + paths.group(builder, medium, large,
        size.medium_count, 4, 10, size.medium_border, 2)
    count = count + paths.group(builder, small, medium,
        size.small_count, 2, 6, size.small_border, 1)

    rooms.at_intersections(builder, 50,
        size.room_min, size.room_max, 1, wall, api.branch)
    rooms.at_positions(builder, medium, size.room_corner_percent,
        size.room_min, size.room_max, 1, wall, api.branch)
    cell_graph.keep_largest_region(builder)

    if builder.bad_random then
        error("Loop Ring random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        loop_count = count,
    }
end

return layout
