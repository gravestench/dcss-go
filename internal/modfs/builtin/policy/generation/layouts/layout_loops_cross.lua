-- Theory of operation: Cross begins with a plus-shaped central room and
-- four arm rooms, connects each arm with divided lines, then grows loops
-- and small rooms around their corners. Dungeon lets the common postpass
-- place stairs; the source's authored stair-room chance applies only in Elf.
local grid = require("policy.generation.grid")
local paths = require("policy.generation.layouts.loop_paths")
local rooms = require("policy.generation.layouts.loop_rooms")
local cell_graph = require("policy.generation.layouts.cell_graph")

local layout = {}

-- Source arm centers and room radii vary slightly between Dungeon and Elf.
local function settings(branch)
    local elf = branch == "Elf"

    return {
        arm = elf and 19 or 20,
        room_min = elf and 2 or 1,
        room_max = elf and 5 or 4,
        corner_percent = elf and 25 or 20,
        stair_room_min = elf and 3 or 2,
    }
end

-- Four source connections bend within eight cells of the central axis.
-- The end points stay inside the arm and plus-shaped rooms.
local function connect_arms(builder, points, center_x, center_y, arm)
    local west = center_x - arm
    local east = center_x + arm
    local north = center_y - arm
    local south = center_y + arm

    paths.line_x(builder, points,
        { x = west, y = center_y },
        { x = center_x - 4, y = center_y },
        center_y - 8, center_y + 8, 0, 3)
    paths.line_x(builder, points,
        { x = center_x + 4, y = center_y },
        { x = east, y = center_y },
        center_y - 8, center_y + 8, 0, 3)
    paths.line_y(builder, points,
        { x = center_x, y = north },
        { x = center_x, y = center_y - 4 },
        center_x - 8, center_x + 8, 0, 3)
    paths.line_y(builder, points,
        { x = center_x, y = center_y + 4 },
        { x = center_x, y = south },
        center_x - 8, center_x + 8, 0, 3)
end

-- The source centers one broad room and one small room on each cross arm.
local function arm_rooms(builder, wall, center_x, center_y, size)
    rooms.shape(builder, center_x, center_y,
        5 + builder:roll(4), "plus", "open", wall)

    local west = size.stair_room_min + paths.low(builder, 2)
    local east = size.stair_room_min + paths.low(builder, 2)
    local north = size.stair_room_min + paths.low(builder, 2)
    local south = size.stair_room_min + paths.low(builder, 2)

    rooms.shape(builder, center_x - size.arm, center_y,
        west, "box", "open", wall)
    rooms.shape(builder, center_x + size.arm, center_y,
        east, "box", "open", wall)
    rooms.shape(builder, center_x, center_y - size.arm,
        north, "box", "open", wall)
    rooms.shape(builder, center_x, center_y + size.arm,
        south, "box", "open", wall)
end

-- Small loops start at divided-line corners. Remaining positions can
-- become additional rooms without modifying the already built arms.
local function grow_arms(builder, points, size, wall, branch,
    center_x, center_y)
    local unused = {}
    local arm = size.arm

    paths.divided(builder, points, center_x - arm, center_y, 5, 10, 3)
    paths.divided(builder, points, center_x + arm, center_y, 5, 10, 3)
    paths.divided(builder, points, center_x, center_y - arm, 5, 10, 3)
    paths.divided(builder, points, center_x, center_y + arm, 5, 10, 3)

    local extras = paths.group(builder, unused, points, 25, 2, 3, 1, 1)

    rooms.at_positions(builder, points, size.corner_percent,
        size.room_min, size.room_max, 1, wall, branch)

    return 4 + extras
end

-- Run the named Dungeon/Elf DES hook. Dungeon has zero authored-stair
-- probability, so the shared stair pass owns all six exits on this floor.
function layout.layout_loops_cross(api)
    local builder = grid.new(api.ctx)
    local wall = paths.wall(builder, api)
    local size = settings(api.branch)
    local center_x = grid.width / 2
    local center_y = grid.height / 2
    local positions = {}

    paths.fill(builder, wall)
    arm_rooms(builder, wall, center_x, center_y, size)
    connect_arms(builder, positions, center_x, center_y, size.arm)

    local count = grow_arms(builder, positions, size, wall,
        api.branch, center_x, center_y)

    -- The source still makes this draw in Dungeon even though its chance
    -- is zero; it must not accidentally author an Elf stair arrangement.
    builder:roll(100)
    cell_graph.keep_largest_region(builder)

    if builder.bad_random then
        error("Loop Cross random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        loop_count = count,
    }
end

return layout
