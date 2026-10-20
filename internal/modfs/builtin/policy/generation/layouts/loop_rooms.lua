-- Theory of operation: Loop rooms grow at saved corridor turns and
-- intersections. Their outlines vary among boxes, diamonds, octagons,
-- crosses, and Elf hexagons. Open rooms widen paths; solid rooms leave a
-- walkable ring around a rock center; outline rooms keep prior interiors.
local grid = require("policy.generation.grid")
local paths = require("policy.generation.layouts.loop_paths")

local rooms = {}

-- Keep authored rooms inside the fixed grid even when a source junction
-- is near the edge of a randomly placed loop.
local function set(builder, x, y, glyph)
    if x > 0 and x < grid.width - 1 and
        y > 0 and y < grid.height - 1 then
        builder:set(x, y, glyph)
    end
end

-- Report whether one relative cell belongs to a room's outer footprint.
local function outer(kind, radius, x, y)
    local ax = math.abs(x)
    local ay = math.abs(y)

    if kind == "box" then
        return ax <= radius and ay <= radius
    elseif kind == "diamond" then
        return ax + ay <= radius
    elseif kind == "octagon" then
        return ax <= radius and ay <= radius and
            ax + ay <= radius + 1
    elseif kind == "plus" then
        return ax <= radius and ay <= radius and
            (ax <= 1 or ay <= 1)
    elseif kind == "hex_ns" then
        local addend = radius % 2
        local width = radius - math.ceil((ay - addend) / 2)

        return ay <= radius and ax <= width
    end

    local addend = radius % 2
    local height = radius - math.ceil((ax - addend) / 2)

    return ax <= radius and ay <= height
end

-- The solid center differs by shape. Its complement inside the footprint
-- is the original room's walkable perimeter.
local function inner(kind, radius, x, y)
    local ax = math.abs(x)
    local ay = math.abs(y)

    if kind == "box" then
        return ax < radius and ay < radius
    elseif kind == "diamond" then
        return ax + ay < radius
    elseif kind == "octagon" then
        return ax + ay < radius + 1 and
            not (ax == radius and y == 0) and
            not (ay == radius and x == 0)
    elseif kind == "plus" then
        return (x == 0 and ay < radius) or
            (y == 0 and ax < radius)
    elseif kind == "hex_ns" then
        local addend = radius % 2
        local width = radius - math.ceil((ay - addend + 2) / 2)

        return ay < radius and ax <= width
    end

    local addend = radius % 2
    local height = radius - math.ceil((ax - addend + 2) / 2)

    return ax < radius and ay <= height
end

-- Draw open, solid, or outline style from the two shape masks. An outline
-- writes only its perimeter and retains older corridors in its center.
function rooms.shape(builder, center_x, center_y, radius,
    kind, style, wall)
    for y = -radius, radius do
        for x = -radius, radius do
            if outer(kind, radius, x, y) then
                local inside = inner(kind, radius, x, y)

                if style == "open" or not inside then
                    set(builder, center_x + x, center_y + y, ".")
                elseif style == "solid" then
                    set(builder, center_x + x, center_y + y, wall)
                end
            end
        end
    end
end

-- Preserve the source's shape and center-style weights. Larger box rooms
-- occasionally become a plus-shaped junction instead.
local function choice(builder, radius, branch)
    if radius < 2 then
        local shape = builder:roll(3) < 2 and "box" or "diamond"
        local style = builder:roll(3) < 2 and "open" or "solid"

        return shape, style
    end

    local draw = builder:roll(6)
    local shape = draw < 3 and "box" or
        draw < 5 and "diamond" or "octagon"
    local center = builder:roll(6)

    if branch == "Elf" then
        local elf = builder:roll(4)

        shape = ({ "box", "diamond", "octagon", "hex_ns" })[elf + 1]
        center = 1 + builder:roll(3)

        if shape == "hex_ns" and builder:one_in(2) then
            shape = "hex_ew"
        end
    end

    if shape == "box" then
        local chance = (radius - 1) * 25

        if center < 3 then
            if builder:chance_in(chance, 100) then
                shape = "plus"
            end
        elseif center < 5 and builder:chance_in(chance, 200) then
            shape = "plus"
        end
    end

    local style = "open"

    if shape == "box" then
        style = center < 3 and "open" or
            center < 5 and "solid" or "outline"
    elseif shape == "diamond" then
        style = center < 2 and "open" or
            center < 5 and "solid" or "outline"
    elseif shape == "octagon" then
        style = center < 3 and "open" or
            center < 5 and "solid" or "outline"
    elseif shape == "plus" or shape == "hex_ns" or
        shape == "hex_ew" then
        style = center < 3 and "open" or "solid"
    end

    return shape, style
end

-- One source room chooses its visual policy once, then paints its footprint.
function rooms.random(builder, x, y, radius, wall, branch)
    local shape, style = choice(builder, radius, branch)

    rooms.shape(builder, x, y, radius, shape, style, wall)
end

-- Consume saved corner positions in random order. A source radius draw
-- favors smaller Dungeon rooms while Elf draws uniformly.
function rooms.at_positions(builder, positions, percent,
    radius_min, radius_max, border, wall, branch)
    local count = 0

    while #positions > 0 do
        local index = builder:roll(#positions) + 1
        local point = positions[index]

        if builder:chance_in(percent, 100) then
            local radius

            if branch == "Elf" then
                radius = radius_min + builder:roll(radius_max - radius_min + 1)
            else
                radius = radius_min + paths.low(builder,
                    radius_max - radius_min + 1)
            end

            local low_x = border + radius_max
            local high_x = grid.width - border - radius_max - 1
            local low_y = border + radius_max
            local high_y = grid.height - border - radius_max - 1
            local x = math.max(low_x, math.min(high_x, point.x))
            local y = math.max(low_y, math.min(high_y, point.y))

            rooms.random(builder, x, y, radius, wall, branch)
            count = count + 1
        end

        positions[index] = positions[#positions]
        positions[#positions] = nil
    end

    return count
end

-- An x-junction has open cardinal neighbors and closed diagonal corners.
-- Scan before painting rooms so earlier room choices cannot bias later tests.
function rooms.at_intersections(builder, percent,
    radius_min, radius_max, border, wall, branch)
    local positions = {}

    for y = radius_max, grid.height - 1 - radius_max do
        for x = radius_max, grid.width - 1 - radius_max do
            if builder:cell(x, y) == "." and
                builder:cell(x - 1, y) == "." and
                builder:cell(x + 1, y) == "." and
                builder:cell(x, y - 1) == "." and
                builder:cell(x, y + 1) == "." and
                builder:cell(x - 1, y - 1) ~= "." and
                builder:cell(x + 1, y - 1) ~= "." and
                builder:cell(x - 1, y + 1) ~= "." and
                builder:cell(x + 1, y + 1) ~= "." then
                positions[#positions + 1] = { x = x, y = y }
            end
        end
    end

    return rooms.at_positions(builder, positions, percent,
        radius_min, radius_max, border, wall, branch)
end

-- Each corner quarter combines a large diamond room, four satellites,
-- crossing corridors, one divided loop, and five possible small loops.
function rooms.corner(builder, center_x, center_y, wall,
    percent, radius_min, radius_max, branch)
    local positions = {}
    local unused = {}
    local west = center_x - 10
    local east = center_x + 10
    local north = center_y - 10
    local south = center_y + 10

    rooms.shape(builder, center_x, center_y, 5, "diamond", "open", wall)
    rooms.shape(builder, west, center_y, 2, "diamond", "open", wall)
    rooms.shape(builder, east, center_y, 2, "diamond", "open", wall)
    rooms.shape(builder, center_x, north, 2, "diamond", "open", wall)
    rooms.shape(builder, center_x, south, 2, "diamond", "open", wall)

    for x = west, east - 1 do
        set(builder, x, center_y, ".")
    end

    for y = north, south do
        set(builder, center_x, y, ".")
    end

    set(builder, center_x + 5, center_y, "+")
    set(builder, center_x - 5, center_y, "+")
    set(builder, center_x, center_y + 5, "+")
    set(builder, center_x, center_y - 5, "+")

    paths.divided(builder, positions, center_x, center_y, 7, 13, 3)

    local extra = paths.group(builder, unused, positions,
        5, 1, 4, 1, 1)

    rooms.at_positions(builder, positions, percent,
        radius_min, radius_max, 1, wall, branch)

    return 1 + extra
end

return rooms
