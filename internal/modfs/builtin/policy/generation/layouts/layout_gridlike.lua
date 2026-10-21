-- Theory of operation: Gridlike partitions the whole floor, chooses
-- branch-specific room and corridor policy once, assigns source-weighted
-- tiles to its cells, and renders open connections between them. The
-- catalog adds stairs after the renderer leaves one connected region.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local graph = require("policy.generation.layouts.cell_graph")
local tiles = require("policy.generation.layouts.gridlike_tiles")
local policy = require("policy.generation.layouts.gridlike_policy")
local render = require("policy.generation.layouts.gridlike_render")
local fills = require("policy.generation.layouts.gridlike_fills")
local material = require("policy.generation.layouts.material")

local layout = {}

-- The source uses a five-to-eight-cell minimum and a maximum selected
-- from that same minimum up to thirteen, giving uneven urban blocks.
local function partition_options(builder)
    local minimum = subdivision.range(builder, 5, 8)
    local maximum = subdivision.range(builder, minimum, 13)

    return {
        guaranteed_divides = 0,
        initial_chance = 90,
        multiplier = 0.9,
        minimum_size_x = minimum,
        minimum_size_y = minimum,
        maximum_size_x = maximum,
        maximum_size_y = maximum,
    }
end

-- Keep the source phase order: partition, branch choices, tile growth,
-- rendering, disconnected-region cleanup, then material theme.
local function layout_gridlike(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local cells, bounds = subdivision.partition(builder,
        partition_options(builder), 2, 8)
    local choices = policy.choose(builder, api.branch, api.depth)
    local edges = graph.edges(cells)

    tiles.assign(builder, cells, edges, bounds, choices)
    render.paint(builder, cells, edges, choices)
    graph.keep_largest_region(builder)

    local records = fills.paint(builder, cells, choices, api)

    material.level(builder, api)

    if builder.bad_random then
        error("Gridlike random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
        edges = edges,
        records = records,
    }
end

layout.layout_gridlike = layout_gridlike

return layout
