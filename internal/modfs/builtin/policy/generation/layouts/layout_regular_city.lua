-- Theory of operation: Regular City reserves a broad open street grid and
-- tries twenty offset buildings. Each accepted building gets a source
-- wall thickness, optional inner structure, and one to several entrances.
-- Lair grows thick rock buildings with few doors; Crypt and Dis retain
-- the more enclosed city materials and inner-room choices.
local grid = require("policy.generation.grid")
local material = require("policy.generation.layouts.material")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- The source random2avg draws twice and averages to cluster wall offsets
-- near each grid cell's center rather than selecting a uniform offset.
local function average(builder, maximum)
    return math.floor((builder:roll(maximum) + builder:roll(maximum)) / 2)
end

-- Source branch conditions replace the generic city's randomized wall
-- and inner-room probabilities before any building coordinates are drawn.
local function settings(builder, api)
    local base_draw = builder:roll(8)
    local base = base_draw < 3 and "#" or
        base_draw < 6 and "c" or "v"
    local options = {
        wall = base,
        thick_two = subdivision.range(builder, 0, 8) *
            subdivision.range(builder, 0, 8),
        thick_three = subdivision.range(builder, 0, 7) *
            subdivision.range(builder, 0, 7),
        thick_four = 0,
        new_wall = subdivision.range(builder, 0, 100),
        inner_box = subdivision.range(builder, 0, 25),
        inner_split = subdivision.range(builder, 0, 25),
        absent = 14,
        max_inset = 5,
    }

    if api.branch == "Lair" then
        local fraction = api.depth / api.branch_bottom

        options.wall = "#"
        options.thick_two = 50 + fraction * 150
        options.thick_three = 20 + fraction * 80
        options.thick_four = 10 + fraction * 40
        options.new_wall = 0
        options.inner_box = 0
        options.inner_split = 0
        options.absent = 0
        options.max_inset = api.depth == api.branch_bottom and 3 or 4
    elseif api.branch == "Dis" then
        options.wall = "#"
        options.thick_two = 0
        options.thick_three = 0
        options.new_wall = 0
        options.inner_box = options.inner_box * 1.5
        options.inner_split = options.inner_split * 2
    end

    return options
end

-- Reserve the source's eight-cell border and street field. Other vaults
-- will later fit into this open space without replacing room walls.
local function streets(builder)
    for y = 8, builder.height - 9 do
        for x = 8, builder.width - 9 do
            builder:set(x, y, ".")
        end
    end
end

-- A room must stay inside the open field and avoid a previously painted
-- building, door, or authored vault cell in its padded rectangle.
local function free_site(builder, room)
    -- The source still iterates its five-by-four lattice on compact Dis.
    -- Columns outside the 40x35 builder are clipped to its edge, which can
    -- reverse a room's bounds. Reject that empty rectangle before a later
    -- entrance draw can place a door beyond the level.
    if room.x1 >= room.x2 or room.y1 >= room.y2 or
        room.x1 < 9 or room.y1 < 9 or
        room.x2 > builder.width - 10 or
        room.y2 > builder.height - 10 then
        return false
    end

    for y = room.y1 - 1, room.y2 + 1 do
        for x = room.x1 - 1, room.x2 + 1 do
            local glyph = builder:cell(x, y)

            if glyph ~= "." then
                return false
            end
        end
    end

    return true
end

-- Painting a thick box changes only its perimeter ring; the center stays
-- open street until its optional inner box or divider is chosen.
local function box(builder, room, wall, thickness)
    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            local edge = x - room.x1 < thickness or
                room.x2 - x < thickness or
                y - room.y1 < thickness or
                room.y2 - y < thickness

            if edge then
                builder:set(x, y, wall)
            end
        end
    end
end

-- Choose the thickest source wall that fits this room and passes its
-- branch-adjusted percentage. Lair can reach four-cell rock rings.
local function thickness(builder, room, options)
    local width = room.x2 - room.x1
    local height = room.y2 - room.y1

    if width > 8 and height > 8 and
        builder:chance_in(options.thick_four, 100) then
        return 4
    elseif width > 6 and height > 6 and
        builder:chance_in(options.thick_three, 100) then
        return 3
    elseif width > 4 and height > 4 and
        builder:chance_in(options.thick_two, 100) then
        return 2
    end

    return 1
end

-- Inner buildings get their own entrance. A divider instead runs across
-- one axis and puts a single door where the source chose to split it.
local function interior(builder, room, options)
    local thickness = room.thickness
    local width = room.x2 - room.x1 - thickness * 2
    local height = room.y2 - room.y1 - thickness * 2

    if width <= 3 or height <= 3 then
        return
    end

    if builder:chance_in(options.inner_box, 100) then
        local inner = {
            x1 = room.x1 + thickness + 1,
            y1 = room.y1 + thickness + 1,
            x2 = room.x2 - thickness - 1,
            y2 = room.y2 - thickness - 1,
        }
        local wall = room.wall

        if builder:chance_in(options.new_wall, 100) then
            wall = material.room(builder, options.branch, options.wall)
        end

        box(builder, inner, wall, 1)

        local x = subdivision.range(builder, inner.x1 + 1, inner.x2 - 1)

        builder:set(x, inner.y1, "+")
    elseif builder:chance_in(options.inner_split, 100) then
        local x = subdivision.range(builder,
            room.x1 + thickness + 1, room.x2 - thickness - 1)
        local y = subdivision.range(builder,
            room.y1 + thickness + 1, room.y2 - thickness - 1)

        if builder:one_in(2) then
            for wall_x = room.x1 + thickness, room.x2 - thickness do
                builder:set(wall_x, y, room.wall)
            end
        else
            for wall_y = room.y1 + thickness, room.y2 - thickness do
                builder:set(x, wall_y, room.wall)
            end
        end

        builder:set(x, y, "+")
    end
end

-- Place one source-sized city block, keeping its coordinates and wall
-- thickness for the later entrance pass.
local function building(builder, column, row, options)
    local x = 8 + column * 13
    local y = 8 + row * 14
    local room = {
        x1 = math.max(9, x + average(builder, options.max_inset)),
        y1 = math.max(9, y + average(builder, options.max_inset)),
        x2 = math.min(builder.width - 10,
            x + 11 - average(builder, options.max_inset)),
        y2 = math.min(builder.height - 10,
            y + 11 - average(builder, options.max_inset)),
    }

    if builder:chance_in(options.absent, 100) or
        not free_site(builder, room) then
        return nil
    end

    room.wall = material.room(builder, options.branch, options.wall)
    room.thickness = thickness(builder, room, options)

    box(builder, room, room.wall, room.thickness)
    interior(builder, room, options)

    return room
end

-- A thick wall gives its outside and inside door positions separate
-- weights. Open gaps become more common in two-cell walls; four-cell
-- walls keep their outside door most of the time.
local function door_style(builder, thickness)
    if thickness == 2 then
        return builder:roll(3) == 0 and "+" or ".",
            builder:roll(4) == 0 and "+" or "."
    elseif thickness == 3 then
        return builder:roll(3) < 2 and "+" or ".",
            builder:roll(3) == 0 and "+" or "."
    elseif thickness == 4 then
        return builder:roll(5) < 4 and "+" or ".",
            builder:one_in(2) and "+" or "."
    end

    return "+", "+"
end

-- Draw a walkable cut through all layers of one wall, with the chosen
-- glyphs only at its outside and inside ends.
local function entrance(builder, room, outer, inner)
    local side = builder:roll(4)
    local thickness = room.thickness
    local x
    local y
    local dx = 0
    local dy = 0

    if side == 0 or side == 1 then
        x = side == 0 and room.x1 or room.x2
        y = subdivision.range(builder, room.y1 + thickness,
            room.y2 - thickness)
        dx = side == 0 and 1 or -1
    else
        x = subdivision.range(builder, room.x1 + thickness,
            room.x2 - thickness)
        y = side == 2 and room.y1 or room.y2
        dy = side == 2 and 1 or -1
    end

    for step = 0, thickness - 1 do
        local glyph = "."

        if step == 0 then
            glyph = outer
        elseif step == thickness - 1 then
            glyph = inner
        end

        builder:set(x + dx * step, y + dy * step, glyph)
    end
end

-- A source room requests one to five entrances, sometimes reduced to two.
-- Lair removes doors increasingly often but leaves their floor openings.
local function add_entrances(builder, room, api)
    local count = math.max(1,
        1 + builder:roll(5) - builder:roll(3))

    if count > 3 and builder:one_in(3) then
        count = 2
    end

    local outer, inner = door_style(builder, room.thickness)

    if outer == "." and builder:one_in(2) then
        count = count + 1
    end

    if inner == "." and builder:one_in(2) then
        count = count + 1
    end

    for _ = 1, count do
        entrance(builder, room, outer, inner)
    end

    if api.branch == "Lair" then
        for y = room.y1, room.y2 do
            for x = room.x1, room.x2 do
                if builder:cell(x, y) == "+" and
                    builder:chance_in(api.depth * 2,
                        api.depth * 2 + api.branch_bottom) then
                    builder:set(x, y, ".")
                end
            end
        end
    end
end

-- Build the source's five-by-four city grid, then open its chosen room
-- entrances after every wall has been placed.
function layout.layout_regular_city(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local options = settings(builder, api)
    local rooms = {}

    options.branch = api.branch
    streets(builder)

    for column = 0, 4 do
        for row = 0, 3 do
            local room = building(builder, column, row, options)

            if room then
                rooms[#rooms + 1] = room
            end
        end
    end

    for _, room in ipairs(rooms) do
        add_entrances(builder, room, api)
    end

    if builder.bad_random then
        error("Regular City random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        rooms = rooms,
    }
end

return layout
