-- Theory of operation: Zot reserves a circular field inside solid rock.
-- Rounded room placeholders block the delve pass, so winding corridors go
-- around them. The placeholders then become rooms with several exits. One
-- connected territory survives the zone pass before stairs are completed.
local grid = require("policy.generation.grid")
local delve = require("policy.generation.layouts.delve")
local shapes = require("policy.generation.layouts.delve_shapes")

local layout = {}
local radius = 28

-- One point constructor keeps the room and corridor coordinates legible.
local function point(x, y)
    return {
        x = x,
        y = y,
    }
end

-- The source maps a 28-cell radius into the 80x70 level. Cells outside
-- remain reserved X so corridors never reach the level boundary.
local function circular_field(builder, center_x, center_y)
    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            builder:set(x, y, "X")
        end
    end

    shapes.circle(builder, center_x, center_y, radius, "x")
end

-- Room centers stay within the circular field. The source's repeated
-- random pick is bounded here to make a malformed random stream fail fast.
local function room_position(builder, center_x, center_y)
    for _ = 1, 1000 do
        local dx = builder:roll(radius * 2 + 1) - radius
        local dy = builder:roll(radius * 2 + 1) - radius

        if dx * dx + dy * dy <= radius * radius then
            return center_x + dx, center_y + dy
        end
    end

    error("Zot circle could not place a room within its boundary")
end

-- Keep each room's footprint for a second render after passages finish.
local function reserve_rooms(builder, center_x, center_y)
    local rooms = {}
    local count = 10 + builder:roll(6)

    for _ = 1, count do
        local x, y = room_position(builder, center_x, center_y)
        local room = {
            x = x,
            y = y,
            radius = 3 + builder:roll(3),
        }

        shapes.round_box(builder, x, y, room.radius, "X", "X")
        rooms[#rooms + 1] = room
    end

    return rooms
end

-- Find a rock cell surrounded by diggable wall, open a seed, then run
-- source delve with a short frontier. A sealed band keeps the next seed
-- from immediately joining the same passage.
local function passages(builder, center_x, center_y)
    local wanted = 15 + builder:roll(6)
    local placed = 0

    for _ = 1, 1000 do
        if placed >= wanted then
            break
        end

        local x, y = room_position(builder, center_x, center_y)
        local around = 0

        for dy = -1, 1 do
            for dx = -1, 1 do
                if builder:cell(x + dx, y + dy) == "x" then
                    around = around + 1
                end
            end
        end

        if builder:cell(x, y) == "x" and around > 6 then
            builder:set(x, y, ".")
            delve.carve(builder, 3, 3, 0, 50 + builder:roll(51), 1)

            -- The source widen_paths pass seals x cells against each
            -- finished passage. Later seeds begin their own winding route
            -- before connect_adjacent_rooms joins those routes.
            local seal = {}

            for py = 1, builder.height - 2 do
                for px = 1, builder.width - 2 do
                    if builder:cell(px, py) == "x" then
                        for dy = -1, 1 do
                            for dx = -1, 1 do
                                if builder:cell(px + dx, py + dy) == "." then
                                    seal[#seal + 1] = point(px, py)
                                end
                            end
                        end
                    end
                end
            end

            for _, point in ipairs(seal) do
                builder:set(point.x, point.y, "X")
            end

            placed = placed + 1
        end
    end

    return placed
end

-- Render a room only if its center was not consumed by another room or a
-- corridor. A room without a legal door leaves its placeholder untouched.
local function place_rooms(builder, rooms)
    local placed = 0

    for _, room in ipairs(rooms) do
        if builder:cell(room.x, room.y) == "X" then
            local doors = 2 + builder:roll(3)

            if shapes.round_box(builder, room.x, room.y,
                room.radius, "x", ".", doors) then
                placed = placed + 1
            end
        end
    end

    return placed
end

-- The source minimum-area check prevents very sparse random draws from
-- winning merely because their layout metadata had a positive weight.
function layout.validate(result)
    return delve.has_minimum_area(result)
end

-- Rooms are rendered after passages; Zot has no cave wall recoloring.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local center_x = math.floor(builder.width / 2)
    local center_y = math.floor(builder.height / 2)

    circular_field(builder, center_x, center_y)

    local rooms = reserve_rooms(builder, center_x, center_y)
    local paths = passages(builder, center_x, center_y)
    local links = shapes.connect_adjacent(builder, 2000)
    local placed = place_rooms(builder, rooms)

    delve.finish(builder)
    delve.keep_largest_region(builder)

    return {
        builder = builder,
        room_count = placed,
        path_count = paths,
        corridor_links = links,
    }
end

return layout
