-- Theory of operation: one Worley field draws small floor veins, a wider
-- deep-water band, and enclosing rock. Depth changes the thresholds and
-- outer padding. Only the largest ordinary-floor region survives the
-- source zone pass; other floor becomes water before shared stairs land.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local noise = require("policy.generation.layouts.procedural_noise")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- The source's depth_fraction is zero at Coc:1 and one at Coc:7.
-- It changes both cave density and the width of its outer rock belt.
local function parameters(builder, api)
    local fraction = (api.depth - 1) /
        math.max(1, api.branch_bottom - 1)
    local scale = 0.95 + subdivision.real(builder, 0, 0.25) -
        fraction * 0.35
    local path_break = 0.15 + subdivision.real(builder, 0, 0.05) +
        fraction * 0.05
    local wall_break = 0.8 - subdivision.real(builder,
        0, 0.6 - path_break)
    local padding = 4 + subdivision.real(builder, 0, 6) +
        fraction * 6

    return {
        field = noise.worley(builder, scale / 4),
        path_break = path_break,
        wall_break = wall_break,
        padding = padding,
    }
end

-- Source boundary_map returns a ramp at both sides of a coordinate. The
-- half-weight x and y terms suppress water and floor near the level rim.
local function paint(builder, params)
    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local x_border = noise.boundary(x, 1, params.padding,
                builder.width - 2 - params.padding, builder.width - 2)
            local y_border = noise.boundary(y, 1, params.padding,
                builder.height - 2 - params.padding, builder.height - 2)
            local value = noise.worley_at(params.field, x, y) + 1 -
                x_border / 2 - y_border / 2

            if value > params.wall_break then
                builder:set(x, y, "#")
            elseif value > params.path_break then
                builder:set(x, y, "w")
            else
                builder:set(x, y, ".")
            end
        end
    end
end

-- The largest ordinary-floor vein is the stair-bearing route. Isolated
-- floor pockets turn into water instead of becoming unreachable stairs.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)

    paint(builder, parameters(builder, api))
    regions.keep_largest_region(builder, { ["."] = true }, "w")

    return { builder = builder }
end

return layout
