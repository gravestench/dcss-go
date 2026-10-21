-- Theory of operation: Dis Jigsaw carves a large ragged outer room and a
-- four-by-four grid of smaller irregular rooms. Offset dividing walls and
-- doors make it hard to tell which side of a room boundary is open ground.
-- A final region pass fills pockets sealed by those new walls.
local grid = require("policy.generation.grid")
local irregular_box = require("policy.generation.layouts.irregular_box")
local rooms = require("policy.generation.layouts.dis_rooms")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local room_separation = 2
local edge_in = 5
local room_in = 4

-- The source scales with the active builder height. Naming the dimensions
-- keeps every wall and door calculation tied to the same room lattice.
local function dimensions(builder)
    local across = 2 * (builder.height / 35)
    local room_size = 1 + 5 * (builder.height / 35)
    local spacing = room_size + room_separation
    local size = spacing * across + room_separation + edge_in * 2
    local first = edge_in + room_separation

    return {
        across = across,
        room_size = room_size,
        spacing = spacing,
        size = size,
        first = first,
        door_min = first + room_in - 1,
        door_max = first + room_size - room_in,
    }
end

-- The outer irregular wall leaves a broad interior for the room lattice.
-- It must fit strictly inside both builder dimensions, as in the source.
local function outer_room(builder, size)
    if size >= builder.width or size >= builder.height then
        error("Dis Jigsaw room lattice exceeds the builder")
    end

    irregular_box.carve(builder, {
        x1 = 0,
        y1 = 0,
        x2 = size - 1,
        y2 = size - 1,
        div_x = size / 4,
        div_y = size / 4,
        in_x = edge_in,
        in_y = edge_in,
        doors = 0,
        wall = "x",
        floor = ".",
    })
end

-- Each smaller box draws a fresh ragged wall and one to three source doors.
-- Overlap with the outer room is intentional and forms jigsaw-like seams.
local function inner_rooms(builder, shape)
    for column = 0, shape.across - 1 do
        for row = 0, shape.across - 1 do
            local x = shape.first + column * shape.spacing
            local y = shape.first + row * shape.spacing

            irregular_box.carve(builder, {
                x1 = x,
                y1 = y,
                x2 = x + shape.room_size - 1,
                y2 = y + shape.room_size - 1,
                div_x = 3,
                div_y = 3,
                in_x = room_in,
                in_y = room_in,
                doors = subdivision.range(builder, 1, 3),
                wall = "x",
                floor = ".",
            })
        end
    end
end

-- Extend a horizontal divider from its new door until an existing wall or
-- a wall immediately above or below ends the run. The door stays open.
local function horizontal_run(builder, x, y, step, size)
    local next_x = x + step

    while next_x > 0 and next_x < size - 1 and
        builder:cell(x, y + 1) ~= "x" and
        builder:cell(x, y - 1) ~= "x" and
        builder:cell(next_x, y) ~= "x" do
        builder:set(next_x, y, "x")
        x = next_x
        next_x = x + step
    end
end

-- The source adds one slightly offset horizontal divider for each gap in
-- the room lattice, making the cut look less like a uniform square grid.
local function horizontal_walls(builder, shape)
    for column = 0, shape.across do
        for row = 0, shape.across - 1 do
            local x = edge_in + column * shape.spacing +
                subdivision.range(builder, 0, room_separation - 1)
            local y = subdivision.range(builder,
                shape.door_min, shape.door_max) + row * shape.spacing

            builder:set(x, y, "+")
            horizontal_run(builder, x, y, -1, shape.size)
            horizontal_run(builder, x, y, 1, shape.size)
        end
    end
end

-- The vertical wall walk uses the same stopping rule with axes swapped.
-- It cannot cross a prior horizontal divider without reaching rock.
local function vertical_run(builder, x, y, step, size)
    local next_y = y + step

    while next_y > 0 and next_y < size - 1 and
        builder:cell(x + 1, y) ~= "x" and
        builder:cell(x - 1, y) ~= "x" and
        builder:cell(x, next_y) ~= "x" do
        builder:set(x, next_y, "x")
        y = next_y
        next_y = y + step
    end
end

-- Add the perpendicular half of the jigsaw wall lattice. These writes can
-- seal a room door, which is why the largest-zone cleanup follows them.
local function vertical_walls(builder, shape)
    for column = 0, shape.across - 1 do
        for row = 0, shape.across do
            local x = subdivision.range(builder,
                shape.door_min, shape.door_max) + column * shape.spacing
            local y = edge_in + row * shape.spacing +
                subdivision.range(builder, 0, room_separation - 1)

            builder:set(x, y, "+")
            vertical_run(builder, x, y, -1, shape.size)
            vertical_run(builder, x, y, 1, shape.size)
        end
    end
end

-- Return source-shaped terrain to the catalog, which owns the later stair
-- pass. The retained single region makes those stairs mutually reachable.
function layout.layout_jigsaw(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local shape = dimensions(builder)

    outer_room(builder, shape.size)
    inner_rooms(builder, shape)
    horizontal_walls(builder, shape)
    vertical_walls(builder, shape)
    rooms.keep_largest(builder)

    if builder.bad_random then
        error("Dis Jigsaw could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
    }
end

return layout
