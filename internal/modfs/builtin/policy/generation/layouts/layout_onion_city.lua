-- Theory of operation: Onion City divides a broad open area into nested
-- rectangular rooms. Each room has one entrance; a source-sized chance
-- gives it either one smaller room or two side-by-side children. The
-- branch and depth change those chances. A connection pass joins the
-- room tree, then Elf adds transparent wall windows and clear doors.
local grid = require("policy.generation.grid")

local layout = {}
local carve_room

-- Source random_range includes both endpoints. Keep all layout decisions
-- on the saved layout stream used by the rest of the procedural catalog.
local function range(builder, first, last)
    return first + builder:roll(last - first + 1)
end

-- Source random_real is continuous. A million possible values are enough
-- for its spacing and window probabilities without a second RNG owner.
local function real(builder)
    return builder:roll(1000000) / 1000000
end

-- Pan ignores the ordinary depth trend and redraws every source parameter.
-- Elsewhere the trend makes a deeper floor prefer more, closer rooms.
local function parameters(builder, api)
    local fraction = api.depth / math.max(api.branch_bottom, 1)
    local spacing_min = 1.9 + fraction * 0.6
    local spacing_range = 0.85 + real(builder) * 1.15
    local single = range(builder, 1, 2 + math.floor(fraction * 6))
    local divide = range(builder, 50, 80) - math.floor(fraction * 30)

    if api.branch == "Pan" then
        spacing_min = 1.8 + real(builder) * 0.95
        spacing_range = 0.95 + real(builder) * 1.05
        single = math.min(range(builder, 1, 10), range(builder, 1, 10))
        divide = range(builder, 40, 90)
    end

    return {
        spacing_min = spacing_min,
        spacing_range = spacing_range,
        single = single,
        divide = divide,
    }
end

-- Rooms are stored so the final pass can join every nested or divided
-- chamber. Painting a later inner room deliberately replaces parent floor.
local function paint_box(builder, bounds, rooms)
    for y = bounds.y1, bounds.y2 do
        for x = bounds.x1, bounds.x2 do
            local boundary = x == bounds.x1 or x == bounds.x2 or
                y == bounds.y1 or y == bounds.y2

            builder:set(x, y, boundary and "#" or ".")
        end
    end

    local side = builder:roll(4)
    local door_x
    local door_y

    if side < 2 then
        door_x = side == 0 and bounds.x1 or bounds.x2
        door_y = range(builder, bounds.y1 + 1, bounds.y2 - 1)
    else
        door_x = range(builder, bounds.x1 + 1, bounds.x2 - 1)
        door_y = side == 2 and bounds.y1 or bounds.y2
    end

    builder:set(door_x, door_y, "+")

    rooms[#rooms + 1] = {
        x = math.floor((bounds.x1 + bounds.x2) / 2),
        y = math.floor((bounds.y1 + bounds.y2) / 2),
    }
end

-- Source single-room children are inset by the selected spacing. Split
-- children may recurse directly or become boxes with a smaller inner room.
local function child(builder, bounds, settings, rooms, spacing, recurse)
    local inner_min = spacing * 2 + 3 + settings.spacing_min
    local width = bounds.x2 - bounds.x1 + 1
    local height = bounds.y2 - bounds.y1 + 1

    if recurse then
        return carve_room(builder, bounds, settings, rooms)
    end

    paint_box(builder, bounds, rooms)

    if width >= inner_min and height >= inner_min then
        local inner = {
            x1 = bounds.x1 + spacing + 1,
            y1 = bounds.y1 + spacing + 1,
            x2 = bounds.x2 - spacing - 1,
            y2 = bounds.y2 - spacing - 1,
        }

        carve_room(builder, inner, settings, rooms)
    end
end

-- Each eligible division point carries one unit of weight. The separate
-- single weight allows a large chamber to contain another nested chamber
-- even when it could also split along either axis.
carve_room = function(builder, bounds, settings, rooms)
    local spacing = math.floor(settings.spacing_min +
        real(builder) * settings.spacing_range)
    local x_min = bounds.x1 + spacing + 2
    local x_max = bounds.x2 - spacing * 2 - 2
    local y_min = bounds.y1 + spacing + 2
    local y_max = bounds.y2 - spacing * 2 - 2
    local x_weight = math.max(0, x_max - x_min + 1)
    local y_weight = math.max(0, y_max - y_min + 1)
    local choice = builder:roll(settings.single + x_weight + y_weight)

    if choice < settings.single then
        child(builder, bounds, settings, rooms, spacing, false)

        return
    end

    if choice < settings.single + x_weight then
        local division = range(builder, x_min, x_max)
        local left = {
            x1 = bounds.x1,
            y1 = bounds.y1,
            x2 = division,
            y2 = bounds.y2,
        }
        local right = {
            x1 = division + spacing + 1,
            y1 = bounds.y1,
            x2 = bounds.x2,
            y2 = bounds.y2,
        }

        child(builder, left, settings, rooms, spacing,
            builder:chance_in(settings.divide, 100))
        child(builder, right, settings, rooms, spacing,
            builder:chance_in(settings.divide, 100))

        return
    end

    local division = range(builder, y_min, y_max)
    local top = {
        x1 = bounds.x1,
        y1 = bounds.y1,
        x2 = bounds.x2,
        y2 = division,
    }
    local bottom = {
        x1 = bounds.x1,
        y1 = division + spacing + 1,
        x2 = bounds.x2,
        y2 = bounds.y2,
    }

    child(builder, top, settings, rooms, spacing,
        builder:chance_in(settings.divide, 100))
    child(builder, bottom, settings, rooms, spacing,
        builder:chance_in(settings.divide, 100))
end

-- The source's adjacent-room postpass opens many walls. Join each child to
-- the closest earlier room so all recursively split chambers share one
-- traversable city instead of leaving isolated rooms beyond the stairs.
local function join_rooms(builder, rooms)
    for index = 2, #rooms do
        local room = rooms[index]
        local nearest
        local distance

        for earlier = 1, index - 1 do
            local other = rooms[earlier]
            local candidate = math.abs(room.x - other.x) +
                math.abs(room.y - other.y)

            if not distance or candidate < distance then
                nearest = other
                distance = candidate
            end
        end

        local x = room.x
        local y = room.y

        while x ~= nearest.x do
            if builder:cell(x, y) == "#" then
                builder:set(x, y, ".")
            end

            x = x + (x < nearest.x and 1 or -1)
        end

        while y ~= nearest.y do
            if builder:cell(x, y) == "#" then
                builder:set(x, y, ".")
            end

            y = y + (y < nearest.y and 1 or -1)
        end

        if builder:cell(x, y) == "#" then
            builder:set(x, y, ".")
        end
    end
end

-- A transparent window needs open space on both sides of the same wall
-- segment. Source Elf uses this check near existing doors so a window
-- never cuts an arbitrary outside rock face.
local function window_at(builder, x, y, chance)
    if builder:cell(x, y) ~= "#" or
        not builder:chance_in(chance, 100) then
        return
    end

    local north_south = builder:cell(x - 1, y) == "." and
        builder:cell(x + 1, y) == "."
    local east_west = builder:cell(x, y - 1) == "." and
        builder:cell(x, y + 1) == "."

    if north_south or east_west then
        builder:set(x, y, "m")
    end
end

-- Elf changes some doors into clear doors and adds nearby windows. Pan
-- keeps opaque doors and walls, as in the source branch-specific script.
local function elf_windows(builder)
    local chance = 20 + builder:roll(31)

    for x = 10, grid.width - 11 do
        for y = 10, grid.height - 11 do
            if builder:cell(x, y) == "+" then
                if builder:chance_in(chance, 100) then
                    builder:set(x, y, "~")
                end

                window_at(builder, x - 2, y, chance)
                window_at(builder, x + 2, y, chance)
                window_at(builder, x, y - 2, chance)
                window_at(builder, x, y + 2, chance)
            end
        end
    end
end

-- Leave an eight-cell rock border and one broad interior site before
-- carving. The source reserves that perimeter for builder vault fitting.
function layout.layout_onion_city(api)
    local builder = grid.new(api.ctx)
    local settings = parameters(builder, api)
    local rooms = {}

    for y = 8, grid.height - 9 do
        for x = 8, grid.width - 9 do
            builder:set(x, y, ".")
        end
    end

    local spacing = math.floor(settings.spacing_min +
        real(builder) * settings.spacing_range)
    local area = {
        x1 = 8 + spacing,
        y1 = 8 + spacing,
        x2 = grid.width - 9 - spacing,
        y2 = grid.height - 9 - spacing,
    }

    carve_room(builder, area, settings, rooms)
    join_rooms(builder, rooms)

    if api.branch == "Elf" then
        elf_windows(builder)
    end

    if builder.bad_random then
        error("Onion City random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        room_count = #rooms,
    }
end

return layout
