-- Theory of operation: a simplex field grades Gehenna into rock at both
-- extremes, lava at low-middle values, and floor between lava and the
-- high rock cutoff. A padded boundary closes the map edge. The source
-- then adds its shared rounded stone buildings, fills isolated floor
-- with lava, and removes lava islands unreachable from the main route.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local shared = require("policy.generation.layouts.gehenna_shared")
local noise = require("policy.generation.layouts.procedural_noise")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local floor_only = {
    ["."] = true,
    ["+"] = true,
}
local floor_and_lava = {
    ["."] = true,
    ["+"] = true,
    l = true,
}

-- Depth makes paths narrower and increases lava in the source. Draw all
-- thresholds before constructing the field to retain that source order.
local function parameters(builder, api)
    local fraction = (api.depth - 1) /
        math.max(1, api.branch_bottom - 1)
    local scale = 1.6 - subdivision.real(builder, 0, 0.3) -
        fraction * 0.4
    local padding = subdivision.range(builder, 2, 6)
    local wall_break = 0.05 + subdivision.real(builder, 0, 0.05) +
        fraction * 0.1
    local lava_break = 0.15 + subdivision.real(builder, 0, 0.1) +
        fraction * 0.15
    local open_break = 0.55 + subdivision.real(builder, 0, 0.05) +
        fraction * 0.15

    return {
        scale = scale,
        padding = padding,
        wall_break = wall_break,
        lava_break = lava_break,
        open_break = open_break,
    }
end

-- A source coin flip distorts the primary simplex domain with two more
-- simplex fields. Their offset scale is inversely proportional to its scale.
local function fields(builder, scale)
    local primary = noise.simplex(builder, scale, true)

    if not builder:one_in(2) then
        return primary, nil
    end

    local offset_x = noise.simplex(builder,
        subdivision.real(builder, 1, 2), true)
    local offset_y = noise.simplex(builder,
        subdivision.real(builder, 1, 2), true)
    local distortion = {
        x = offset_x,
        y = offset_y,
        scale = subdivision.real(builder, 0.5, 1) / scale,
    }

    return primary, distortion
end

-- Evaluate the primary field at a possibly displaced coordinate. No RNG
-- is consumed per cell, so rerendering a saved map yields the same cave.
local function sample(primary, distortion, x, y)
    if distortion then
        local moved_x = x + noise.simplex_at(distortion.x, x, y) *
            distortion.scale
        local moved_y = y + noise.simplex_at(distortion.y, x, y) *
            distortion.scale

        return noise.simplex_at(primary, moved_x, moved_y)
    end

    return noise.simplex_at(primary, x, y)
end

-- The four-cell hard border and random padded band suppress floor near
-- the immutable rim. Values beyond the open cutoff remain rock.
local function paint(builder, params, primary, distortion)
    local hard = 4
    local padded = hard + params.padding
    local far_x = builder.width - 1 - hard
    local far_y = builder.height - 1 - hard

    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local x_border = noise.boundary(x,
                hard, padded, far_x - params.padding, far_x)
            local y_border = noise.boundary(y,
                hard, padded, far_y - params.padding, far_y)
            local value = sample(primary, distortion, x, y) *
                x_border * y_border

            if value < params.wall_break or
                value >= params.open_break then
                builder:set(x, y, "#")
            elseif value < params.lava_break then
                builder:set(x, y, "l")
            else
                builder:set(x, y, ".")
            end
        end
    end
end

-- Both source zone passes have different traversability: the first
-- replaces remote floor with lava, and the second keeps the largest
-- territory traversable by a flying actor before sealing other lava.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local params = parameters(builder, api)
    local primary, distortion = fields(builder, params.scale)

    paint(builder, params, primary, distortion)

    local buildings = shared.add_buildings(builder, api)

    regions.keep_largest_region(builder, floor_only, "l")
    regions.keep_largest_region(builder, floor_and_lava)

    return {
        builder = builder,
        room_count = buildings,
    }
end

return layout
