-- Theory of operation: Big Grid carves a wide Lair passage grid, then
-- leaves the interiors of its subdivided cells as rock. The two-in-three
-- outer-corridor draw changes both the split rate and edge shape. The
-- resulting open region is kept connected before the stair pass.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local cell_graph = require("policy.generation.layouts.cell_graph")

local layout = {}

-- The source option groups belong to the layout: the shared subdivider
-- handles geometry, while Big Grid owns its wide corridors and jitter.
function layout.layout_big_grid(api)
    local builder = grid.new(api.ctx)
    local edge = builder:chance_in(2, 3)
    local options = {
        guaranteed_divides = edge and 0 or 2,
        initial_chance = edge and 80 or 100,
        multiplier = edge and 0.80 or 0.90,
        minimum_size_x = 16,
        minimum_size_y = 16,
    }
    local paint = {
        fill_chance = 100,
        corridor_width = subdivision.range(builder, 6, 8),
        outer_corridor = edge,
        jitter = edge and builder:one_in(2),
        jitter_min = -2,
        jitter_max = 2,
    }
    local cells = subdivision.render(builder, options, paint)

    cell_graph.keep_largest_region(builder)

    if builder.bad_random then
        error("Big Grid could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        cells = cells,
    }
end

return layout
