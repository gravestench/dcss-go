-- Theory of operation: Shoals begins as deep sea with raised island centers.
-- The source builder creates 20 minus two per local depth, adds small
-- auxiliary bumps and occasional high cliffs, smooths the height field,
-- then paints rock, floor, shallow water, and deep water by height band.
-- This Lua builder owns only generation-local arrays; the level owns the
-- resulting dense terrain grid and the shared layout postpass owns stairs.
local grid = require("policy.generation.grid")
local heights = require("constants.shoals_heights")

local layout = {}

local margin = 6
local deep_height = heights.DEEP
local rock_height = heights.ROCK
local floor_height = heights.FLOOR
local shallow_height = heights.SHALLOW

-- Keep source-style inclusive ranges on the layout stream rather than
-- depending on module load order or an unrelated policy's random calls.
local function between(builder, first, last)
    return first + builder:roll(last - first + 1)
end

-- A fresh heightmap is private to one floor. Its sea baseline is below
-- the shallow-water threshold so the outer edge remains deep water.
local function empty_heights()
    local heights = {}

    for y = 1, grid.height do
        heights[y] = {}

        for x = 1, grid.width do
            heights[y][x] = deep_height
        end
    end

    return heights
end

-- Each island center contributes a steep heart and a softer shoreline.
-- A few irregular auxiliary circles create the source's broken coastlines
-- rather than perfectly round, isolated discs.
local function add_bump(heights, center_x, center_y, radius, rise)
    for y = math.max(margin, center_y - radius),
        math.min(grid.height - margin - 1, center_y + radius) do
        for x = math.max(margin, center_x - radius),
            math.min(grid.width - margin - 1, center_x + radius) do
            local dx = x - center_x
            local dy = y - center_y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= radius then
                local influence = 1 - distance / (radius + 1)

                heights[y + 1][x + 1] = heights[y + 1][x + 1] +
                    math.floor(rise * influence)
            end
        end
    end
end

-- Source local depth reduces island count, making lower Shoals wetter.
-- Each center has a primary rise and zero to three nearby auxiliary rises.
local function build_islands(builder, heights, depth)
    local count = 20 - (depth - 1) * 2

    for _ = 1, count do
        local x = between(builder, margin + 4, grid.width - margin - 5)
        local y = between(builder, margin + 4, grid.height - margin - 5)
        local radius = between(builder, 3, 10)
        local rise = between(builder, 80, 110)

        add_bump(heights, x, y, radius, rise)

        for _ = 1, between(builder, 0, 3) do
            local offset_x = between(builder, -10, 10)
            local offset_y = between(builder, -10, 10)
            local child_x = math.max(margin,
                math.min(grid.width - margin - 1, x + offset_x))
            local child_y = math.max(margin,
                math.min(grid.height - margin - 1, y + offset_y))

            add_bump(heights, child_x, child_y,
                between(builder, 2, 7), between(builder, 50, 65))
        end
    end
end

-- Rare high ridges make the stone and rock bands reachable. Their short
-- runs are separate from the lower islands, matching the source's cliffs.
local function build_cliffs(builder, heights)
    for _ = 1, between(builder, 0, 6) do
        local x = between(builder, margin * 2,
            grid.width - margin * 2 - 1)
        local y = between(builder, margin * 2,
            grid.height - margin * 2 - 1)
        local horizontal = builder:one_in(2)

        for step = 0, between(builder, 2, 5) do
            local point_x = x + (horizontal and step * 2 or 0)
            local point_y = y + (horizontal and 0 or step * 2)

            add_bump(heights, point_x, point_y, 3,
                between(builder, 100, 130))
        end
    end
end

-- Average neighboring heights into a separate field so shorelines become
-- traversable bands without the iteration direction moving whole islands.
local function smooth(heights)
    local result = empty_heights()

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local total = 0

            for dy = -1, 1 do
                for dx = -1, 1 do
                    total = total + heights[y + dy + 1][x + dx + 1]
                end
            end

            result[y + 1][x + 1] = math.floor(total / 9)
        end
    end

    return result
end

-- Translate the source height bands to DES terrain glyphs. The immutable
-- edge stays deep sea, while the shared stair postpass chooses land cells.
local function paint(builder, heights)
    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local height = heights[y + 1][x + 1]
            local glyph = "w"

            if height >= rock_height then
                glyph = "x"
            elseif height >= floor_height then
                glyph = "."
            elseif height >= shallow_height then
                glyph = "W"
            end

            builder:set(x, y, glyph)
        end
    end
end

-- Build terrain only. The caller adds exits after the hook returns and
-- checks the same bounded RNG stream used by the other Lua layouts.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local heights = empty_heights()

    build_islands(builder, heights, api.depth)
    build_cliffs(builder, heights)
    heights = smooth(smooth(heights))
    paint(builder, heights)

    if builder.bad_random then
        error("Shoals random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        heightmap = heights,
    }
end

return layout
