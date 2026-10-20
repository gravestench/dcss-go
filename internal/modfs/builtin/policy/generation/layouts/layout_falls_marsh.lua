-- Theory of operation: Falls Marsh samples a Worley field through an
-- inverse polar transform, turning feature-cell seams into long drips.
-- The source keeps one initial floor territory, grows mixed water, stone,
-- and tree pools, then applies substitutions that favor shallow water.
-- A last water-aware zone pass blocks stranded floor or deep-water pockets.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local cleanup = require("policy.generation.layouts.cave_cleanup")
local noise = require("policy.generation.layouts.procedural_noise")
local pools = require("policy.generation.layouts.pools")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local open_floor = { ["."] = true }
local water_route = {
    ["."] = true,
    W = true,
    w = true,
}

-- The source border is measured from an inset sixteen-cell rectangle.
-- Values outside that rectangle are maximally suppressed before carving.
local function inset_border(x, y)
    local margin = 16
    local padding = 16
    local near = math.min(x - margin, y - margin,
        grid.width - 1 - margin - x,
        grid.height - 1 - margin - y)
    local progress = math.max(0,
        math.min(1, near / (padding + 1)))

    return 1 - progress
end

-- Inverse polar sampling unwraps a circular Worley field along x. The
-- resulting seams become narrow vertical drips of varying length.
local function polar_value(field, repetitions, x, y)
    local radius = grid.height / 1.8
    local scale_x = 100 * grid.width / repetitions
    local scale_y = grid.height / 2
    local angle = x / scale_x * 2 * math.pi
    local distance = radius * y / scale_y
    local sample_x = math.sin(angle) * distance
    local sample_y = math.cos(angle) * distance

    return noise.worley_at(field, sample_x, sample_y)
end

-- Tree is the uncarved source terrain. Keeping the largest floor region
-- before pool growth gives stairs one mainland rather than isolated drips.
local function paint_drips(builder, field, repetitions)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local value = polar_value(field, repetitions, x, y) +
                0.35 * inset_border(x, y)

            builder:set(x, y, value < 0.35 and "." or "t")
        end
    end

    regions.keep_largest_region(builder, open_floor, "t")
end

-- The source's branch-depth weights choose the pool material before
-- the later substitutions. Use a stable list so file order cannot matter.
local function pool_contents(depth)
    return {
        { glyph = "w", weight = 75 + depth * 10 },
        { glyph = "W", weight = 60 - depth * 10 },
        { glyph = "c", weight = 5 + depth * 5 },
        { glyph = "t", weight = 10 },
    }
end

-- Each call performs one source SUBST pass. New glyphs made by an earlier
-- pass participate in the later one, so pass order changes marsh terrain.
local function substitute(builder, target, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == target then
                local draw = builder:roll(total)

                for _, choice in ipairs(choices) do
                    if draw < choice.weight then
                        builder:set(x, y, choice.glyph)
                        break
                    end

                    draw = draw - choice.weight
                end
            end
        end
    end
end

-- The source converts most deep water to shallow water, opens almost
-- every stone pool, and increases shallow water with Swamp depth.
local function soften_pools(builder, depth)
    local water = {
        { glyph = "W", weight = 75 },
        { glyph = "t", weight = 1 },
    }

    substitute(builder, "W", water)
    substitute(builder, "w", water)
    substitute(builder, "c", {
        { glyph = ".", weight = 570 },
        { glyph = "w", weight = 1 },
        { glyph = "t", weight = 1 },
    })
    substitute(builder, ".", {
        { glyph = ".", weight = 71 - depth * 4 },
        { glyph = "W", weight = 29 + depth * 4 },
    })
    substitute(builder, "#", {
        { glyph = "t", weight = 1 },
    })
end

-- Source validation counts ordinary floor and shallow water, since a
-- Swamp route can be passable even when much of its surface is flooded.
function layout.validate(result)
    local count = 0

    for _, row in ipairs(result.builder:rows()) do
        for glyph in row:gmatch(".") do
            if glyph == "." or glyph == "W" then
                count = count + 1
            end
        end
    end

    return count > grid.width * grid.height / 10
end

-- The source puts pool growth before SUBST and removes isolated shallow
-- cells before the final pass that treats both waters as traversable.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local repetitions = subdivision.range(builder, 70, 85)
    local field = noise.worley(builder, 7.5 / repetitions)

    paint_drips(builder, field, repetitions)

    local pool_size = 8 + builder:roll(8)
    local pool_count = pools.add(builder,
        pool_size, pool_contents(api.depth))

    soften_pools(builder, api.depth)
    cleanup.remove_isolated(builder, "W", 80, false)
    regions.keep_largest_region(builder, water_route, "t")

    return {
        builder = builder,
        pool_count = pool_count,
    }
end

return layout
