-- Theory of operation: Corners starts with a large square hallway. Each
-- corner receives a diamond junction, four satellites, a bent ring, small
-- loops, and optional rooms. The four repeated quarters share one readable
-- construction rule but retain their independent source random choices.
local grid = require("policy.generation.grid")
local paths = require("policy.generation.layouts.loop_paths")
local rooms = require("policy.generation.layouts.loop_rooms")
local cell_graph = require("policy.generation.layouts.cell_graph")

local layout = {}

-- The source draws the square's right and bottom edges one cell farther
-- than its top and left runs; each quarter connects through that ring.
local function outer_hall(builder, west, east, north, south)
    for x = west, east - 1 do
        builder:set(x, north, ".")
        builder:set(x, south, ".")
    end

    for y = north, south - 1 do
        builder:set(west, y, ".")
        builder:set(east, y, ".")
    end
end

-- Run all four source quarters after the common square has been carved.
function layout.layout_loops_corners(api)
    local builder = grid.new(api.ctx)
    local wall = paths.wall(builder, api)
    local radius_min = api.branch == "Elf" and 2 or 1
    local radius_max = api.branch == "Elf" and 5 or 4
    local percent = api.branch == "Elf" and 40 or 25
    local west = grid.width / 2 - 17
    local east = grid.width / 2 + 17
    local north = grid.height / 2 - 17
    local south = grid.height / 2 + 17

    paths.fill(builder, wall)
    outer_hall(builder, west, east, north, south)

    local count = 0

    count = count + rooms.corner(builder, west, north,
        wall, percent, radius_min, radius_max, api.branch)
    count = count + rooms.corner(builder, west, south,
        wall, percent, radius_min, radius_max, api.branch)
    count = count + rooms.corner(builder, east, north,
        wall, percent, radius_min, radius_max, api.branch)
    count = count + rooms.corner(builder, east, south,
        wall, percent, radius_min, radius_max, api.branch)
    cell_graph.keep_largest_region(builder)

    if builder.bad_random then
        error("Loop Corners random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        loop_count = count,
    }
end

return layout
