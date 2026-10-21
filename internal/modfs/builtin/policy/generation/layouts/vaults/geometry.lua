-- Theory of operation: Vaults primary layouts paint large rectangular floor
-- and wall regions before inserting rooms. A level chooses one wall material
-- from the source depth weights, so its room surrounds look coherent.
local grid = require("policy.generation.grid")

local geometry = {}

-- Use source local-depth weights: stone recedes while metal and crystal
-- become more common as the player approaches the fifth-floor vault.
function geometry.wall(builder, depth)
    local stone = math.max(0, 4 - depth) * 10
    local metal = math.max(0, depth - 2) * 20
    local crystal = math.max(0, depth - 2)
    local total = stone + metal + crystal
    local draw = builder:roll(total)

    if draw < stone then
        return "c"
    elseif draw < stone + metal then
        return "v"
    end

    return "b"
end

-- Paint one inclusive source rectangle, clipping its bounds to the inner
-- grid. The immutable edge stays wall even when a motif asks for full floor.
function geometry.rectangle(builder, x1, y1, x2, y2, glyph)
    for y = math.max(1, y1), math.min(grid.height - 2, y2) do
        for x = math.max(1, x1), math.min(grid.width - 2, x2) do
            builder:set(x, y, glyph)
        end
    end
end

-- Source crawl.random_range includes both endpoints. Keep one bounded draw
-- here rather than repeating off-by-one arithmetic in every motif.
function geometry.range(builder, first, last)
    if first > last then
        error("Vaults geometry has an inverted source range")
    end

    return first + builder:roll(last - first + 1)
end

-- A sparse maze starts with one room and adds connected rectangular lobes.
-- Carve the shared wall as a door so later stair placement sees one region.
function geometry.join(builder, from, to)
    local x = from.x
    local y = from.y

    while x ~= to.x do
        builder:set(x, y, ".")
        x = x + (to.x > x and 1 or -1)
    end

    while y ~= to.y do
        builder:set(x, y, ".")
        y = y + (to.y > y and 1 or -1)
    end

    builder:set(x, y, ".")
end

-- Fill rock only once, before source floor and wall paint. An authored room
-- may later replace selected cells without changing the chosen level theme.
function geometry.theme(builder, depth)
    local wall = geometry.wall(builder, depth)

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            builder:set(x, y, wall)
        end
    end

    return wall
end

return geometry
