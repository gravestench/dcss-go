-- Theory of operation: the source Swamp builder starts every height at
-- minus nineteen, scatters small positive islands from jittered sample
-- points, and smooths the whole heightmap once. Height bands become
-- mangrove, floor, or shallow water. Local depth moves the upper water
-- threshold, making deeper Swamp levels wetter without changing this
-- layout's declared weight or inventing a second terrain generator.
local grid = require("policy.generation.grid")

local layout = {}

local sample_margin = 15
local terrain_margin = 6
local initial_height = -19
local full_circle = 360

-- Match the source's inclusive random_range and keep every draw on the
-- layout RNG stream so changing an unrelated mod file cannot change it.
local function between(builder, minimum, maximum)
    return minimum + builder:roll(maximum - minimum + 1)
end

-- DCSS chooses a random angle on a fixed-radius circle, truncating the
-- resulting offsets to integer cells. Retry only when the point would
-- violate the requested map margin, as the source builder does.
local function random_point(builder, center, radius, margin)
    for _ = 1, 70 do
        local angle = builder:roll(full_circle) * math.pi / 180
        local dx = math.modf(radius * math.cos(angle))
        local dy = math.modf(radius * math.sin(angle))
        local x = center.x + dx
        local y = center.y + dy

        if x >= margin and x <= grid.width - 1 - margin and
            y >= margin and y <= grid.height - 1 - margin then
            return x, y
        end
    end

    return nil, nil
end

-- The heightmap belongs only to this generation call. No mutable map
-- state escapes into a module global or the ECS world during carving.
local function empty_heights()
    local heights = {}

    for y = 1, grid.height do
        heights[y] = {}

        for x = 1, grid.width do
            heights[y][x] = initial_height
        end
    end

    return heights
end

-- A slushy patch contributes several small positive bumps. The source
-- uses a depth-scaled point count and adjusts the height range toward
-- the center of the map, preserving open islands within the mangroves.
local function add_patch(builder, heights, center, depth_multiplier)
    local central_x = math.floor(grid.width / 2)
    local central_y = math.floor(grid.height / 2)
    local dx = central_x - center.x
    local dy = central_y - center.y
    local offset = math.modf((1600 - dx * dx - dy * dy) * 10 / 1600)
    local count = between(builder, 5,
        25 - math.floor(depth_multiplier / 2))
    local radius = between(builder, 2, 6)

    for _ = 1, count do
        local local_radius = builder:roll(radius + 1)
        local x, y = random_point(builder, center, local_radius,
            sample_margin)

        if x then
            heights[y + 1][x + 1] = heights[y + 1][x + 1] +
                between(builder, 8 + offset, 17 + offset)
        end
    end
end

-- Jitter each four-cell sample on the source's fifteen-cell inset.
-- These samples are dense enough that smoothing joins nearby patches
-- into islands but still leaves water and mangrove between them.
local function scatter(builder, heights, depth)
    local multiplier = (depth - 1) * 3

    for y = sample_margin, grid.height - sample_margin - 2, 4 do
        for x = sample_margin, grid.width - sample_margin - 2, 4 do
            local center_x, center_y = random_point(builder,
                { x = x, y = y }, 9, sample_margin)

            if center_x then
                add_patch(builder, heights,
                    { x = center_x, y = center_y }, multiplier)
            end
        end
    end
end

-- One source smoothing pass visits mirrored quadrants in place. Its
-- nine neighbors receive squared-distance weights 4, 3, and 2; an
-- out-of-bounds neighbor contributes nothing to the average.
local function smooth_at(heights, x, y)
    local total = 0
    local divisor = 0

    for ny = math.max(0, y - 1), math.min(grid.height - 1, y + 1) do
        for nx = math.max(0, x - 1), math.min(grid.width - 1, x + 1) do
            local dx = x - nx
            local dy = y - ny
            local distance_weight = 4 - dx * dx - dy * dy

            total = total + heights[ny + 1][nx + 1] * distance_weight
            divisor = divisor + distance_weight
        end
    end

    heights[y + 1][x + 1] = math.modf(total / divisor)
end

-- This visitation order matches the source quadrant traversal rather
-- than replacing it with a second buffer, which would change islands.
local function smooth(heights)
    local half_x = math.floor(grid.width / 2)
    local half_y = math.floor(grid.height / 2)

    for y = half_y - 1, 0, -1 do
        for x = half_x - 1, 0, -1 do
            smooth_at(heights, x, y)
            smooth_at(heights, 2 * half_x - x - 1, y)
            smooth_at(heights, x, 2 * half_y - y - 1)
            smooth_at(heights, 2 * half_x - x - 1,
                2 * half_y - y - 1)
        end
    end
end

-- The private q glyph lets the shared source-row decoder install the
-- already supported mangrove feature directly in the Go terrain grid.
-- The six-cell border always remains mangrove, independent of height.
local function paint(builder, heights, depth)
    local upper_water = 8 - depth * 2

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = "q"

            if x >= terrain_margin and y >= terrain_margin and
                x < grid.width - terrain_margin and
                y < grid.height - terrain_margin then
                local height = heights[y + 1][x + 1]

                if height > upper_water then
                    glyph = "W"
                elseif height > -8 then
                    glyph = "."
                elseif height > -10 then
                    glyph = "W"
                end
            end

            builder:set(x, y, glyph)
        end
    end
end

-- Build only the terrain; the shared layout postpass owns stairs and the
-- Go level owns the resulting dense grid during play and save/restore.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local heights = empty_heights()

    scatter(builder, heights, api.depth)
    smooth(heights)
    paint(builder, heights, api.depth)

    if builder.bad_random then
        error("Swamp random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
    }
end

return layout
