-- Theory of operation: the source room layout tries many small rooms in the
-- inner Dungeon, keeping at most thirty. A common draw prevents overlap;
-- another chooses whether accepted rooms are joined immediately or in a
-- final pass. The room shape draw gives rectangular or rounded rooms in D.
-- Exit placement remains the responsibility of the shared stair postpass.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.room_geometry")

local layout = {}

-- Inclusive room bounds match the .des choices. The upper limits stay well
-- inside the outer rock rim, leaving space for later vault placement.
local function random_room(builder)
    local room = {
        x1 = 10 + builder:roll(50),
        y1 = 10 + builder:roll(40),
    }

    room.x2 = room.x1 + 2 + builder:roll(8)
    room.y2 = room.y1 + 2 + builder:roll(8)

    return room
end

-- Rectangular rooms replace only rock, so the layout does not erase an
-- earlier corridor when overlap is allowed by the source exclusivity draw.
local function rectangle(builder, room)
    geometry.fill_rock(builder, room)
end

-- Elf uses a shrinking sequence of rectangles to chamfer room corners.
-- This is kept separate because its corridor policy also differs from D.
local function octagon(builder, room)
    local short_side = math.min(room.x2 - room.x1 - 1, room.y2 - room.y1 - 1)
    local corner_size = 1 + builder:roll(short_side)

    for offset = 0, corner_size do
        local inset = corner_size - offset

        geometry.fill_rock(builder, {
            x1 = room.x1 + offset,
            y1 = room.y1 + inset,
            x2 = room.x2 - offset,
            y2 = room.y2 - inset,
        })
    end
end

-- Preserve the source script's elongated-circle sequence. Its step count
-- can be negative for nearly square boxes, in which case this draw makes
-- no floor and the following corridor pass can still connect the anchors.
local function rounded(builder, room)
    local x_delta = room.x2 - room.x1
    local y_delta = room.y2 - room.y1
    local radius = math.max(x_delta, y_delta) / 2
    local steps = math.abs(y_delta - x_delta) - radius

    for offset = 1, steps do
        if y_delta > x_delta then
            geometry.circle(builder, room.x1 + radius, room.y1 + radius + offset, radius)
            geometry.circle(builder, room.x2 - radius, room.y1 + radius + offset, radius)
        else
            geometry.circle(builder, room.x1 + radius + offset, room.y1 + radius, radius)
            geometry.circle(builder, room.x1 + radius + offset, room.y2 - radius, radius)
        end
    end
end

-- Shape selection is owned by this layout: D alternates rectangles and
-- rounded attempts, while the source Elf branch always chooses octagons.
local function draw_room(builder, room, elf)
    if elf then
        octagon(builder, room)
    elseif builder:roll(2) == 0 then
        rectangle(builder, room)
    else
        rounded(builder, room)
    end
end

-- Port the source acceptance and joining loop as one operation so its RNG
-- order stays visible. Thirty accepted rooms cap the floor's density.
local function carve(builder, elf)
    local attempts = 30 + builder:roll(90)
    local exclusive = not builder:one_in(10)
    local deferred_joins = builder:roll(2) == 0
    local accepted = {}

    for _ = 0, attempts do
        local room = random_room(builder)

        if not exclusive or geometry.non_rock_count(builder, room) == 0 then
            draw_room(builder, room, elf)

            if #accepted > 0 and not deferred_joins then
                geometry.join(builder, geometry.center(room), geometry.center(accepted[#accepted]), elf)
            end

            accepted[#accepted + 1] = room

            if #accepted >= 30 then
                break
            end
        end
    end

    if deferred_joins then
        for index = 2, #accepted do
            geometry.join(builder, geometry.center(accepted[index]), geometry.center(accepted[index - 1]), elf)
        end
    end

    return accepted
end

-- A named DES hook creates terrain through the shared grid owner. The
-- caller subsequently completes stairs, places vaults, and populates it.
function layout.layout_rooms(api)
    local builder = grid.new(api.ctx)
    local accepted = carve(builder, api.branch == "Elf")

    if builder.bad_random then
        error("room layout random source failed to provide a bounded draw")
    end

    if #accepted == 0 then
        error("room layout accepted no rooms")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        rooms = accepted,
    }
end

return layout
