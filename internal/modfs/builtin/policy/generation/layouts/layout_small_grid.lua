-- Theory of operation: source Small Grid subdivides a large floor at least
-- four levels deep, then leaves most cell interiors as rock. Thin strips
-- between them become passages. A one-in-four draw leaves an exterior loop,
-- and independent side jitter keeps repeated cells from looking identical.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Draw the source grid options per floor, then pass them to the shared
-- subdivision painter. The source DES decides where this layout is eligible.
function layout.layout_small_grid(api)
    local builder = grid.new(api.ctx)
    local outer = builder:one_in(4)
    local options = {
        guaranteed_divides = 4,
        initial_chance = 120,
        multiplier = 0.95,
        minimum_size_x = 6,
        minimum_size_y = 6,
    }
    local paint = {
        fill_chance = 80,
        corridor_width = subdivision.range(builder, 1, 2),
        outer_corridor = outer,
        jitter = builder:roll(2) == 0,
        jitter_min = -1,
        jitter_max = subdivision.range(builder, 0, 1),
    }
    local cells = subdivision.render(builder, options, paint)

    if builder.bad_random then
        error("small grid random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
    }
end

return layout
