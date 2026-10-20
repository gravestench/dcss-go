-- Theory of operation: a weighted circle, cross, doughnut, or simplex
-- silhouette defines the large cave. A second simplex or Worley field
-- roughens that shape, with optional domain distortion before the fields
-- are added. The source then keeps one floor region and applies its cave
-- theme. All fields draw offsets once, before map cells are sampled.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local material = require("policy.generation.layouts.material")
local noise = require("policy.generation.layouts.procedural_noise")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local center_x = grid.width / 2
local center_y = grid.height / 2
local circle_radius = math.min(grid.width, grid.height) / 2 - 2

-- The source chooses the four silhouettes with weights 12:5:8:20.
-- Each kind keeps only the parameters it needs for later pure sampling.
local function choose_shape(builder, width)
    local draw = builder:roll(45)

    if draw < 12 then
        return { kind = "circle" }
    elseif draw < 17 then
        return {
            kind = "cross",
            width = width,
        }
    elseif draw < 25 then
        local shape = {
            kind = "donut",
            width = width,
            outer = subdivision.real(builder, 0.6, 1),
            channel = subdivision.real(builder, 0.3, 0.5),
        }

        if builder:chance_in(2, 3) then
            if builder:one_in(2) then
                shape.bar = "straight"
                shape.horizontal = builder:one_in(2)
            else
                shape.bar = "radial"
                shape.phase = subdivision.real(builder, 0, 1)
                shape.spoke_width = subdivision.real(builder, 0.04, 0.2)
            end

            shape.central_room = builder:chance_in(2, 3)
        end

        return shape
    end

    return {
        kind = "simplex",
        field = noise.simplex(builder,
            subdivision.real(builder, 0.1, 0.8), true),
        multiplier = subdivision.real(builder, 2, 3),
    }
end

-- Two source bar fields form a cross. The lower of the bar-complement
-- values opens whichever arm a sample lies within.
local function cross_value(shape, x, y)
    local horizontal = noise.bar(y, center_y,
        shape.width, shape.width / 2)
    local vertical = noise.bar(x, center_x,
        shape.width, shape.width / 2)

    return 1 - math.max(horizontal, vertical)
end

-- A straight bridge crosses the ring on one axis. Outside the outer
-- circle, the source raises its value so this bridge does not leak away.
local function straight_bridge(shape, distance, x, y)
    local position = shape.horizontal and center_y or center_x
    local coordinate = shape.horizontal and y or x
    local value = 1 - noise.bar(coordinate,
        position, shape.width, shape.width / 2)

    if distance > 1 then
        value = value + (distance - 1) * 10
    end

    return value
end

-- Two opposite radial spokes offer a different ring crossing. The
-- source's phase rotates them together without a separate random field.
local function radial_bridge(shape, distance, x, y)
    local radial = noise.radial(x, y,
        center_x, center_y, shape.phase)
    local width = shape.spoke_width
    local first = noise.boundary(radial,
        0, width / 3, width * 2 / 3, width)
    local second = noise.boundary(radial,
        0.5, 0.5 + width / 3,
        0.5 + width * 2 / 3, 0.5 + width)
    local value = 1 - first - second

    if distance > 1 then
        value = value + (distance - 1) * 20
    end

    return value
end

-- The ring's four boundaries give it a broad floor band. An optional
-- central room lowers its value only after a bridge has been selected.
local function donut_value(shape, x, y)
    local distance = noise.distance(x, y,
        center_x, center_y, circle_radius)
    local outer = shape.outer
    local channel = shape.channel
    local value = 1 - noise.boundary(distance,
        outer - channel, outer - channel * 2 / 3,
        outer - channel / 3, outer)

    if shape.central_room then
        value = value - noise.boundary(distance,
            0.05, 0.05 + channel / 3,
            0.05 + channel * 2 / 3, 0.05 + channel)
    end

    if shape.bar == "straight" then
        value = value * straight_bridge(shape, distance, x, y)
    elseif shape.bar == "radial" then
        value = value * radial_bridge(shape, distance, x, y)
    end

    return value
end

-- Sampling the selected silhouette is pure, which keeps seed behavior
-- independent of x/y iteration order during the final render pass.
local function shape_value(shape, x, y)
    if shape.kind == "circle" then
        local distance = noise.distance(x, y,
            center_x, center_y, circle_radius)

        return math.max(0, math.min(1, (distance - 0.5) * 2))
    elseif shape.kind == "cross" then
        return cross_value(shape, x, y)
    elseif shape.kind == "donut" then
        return donut_value(shape, x, y)
    end

    return noise.simplex_at(shape.field, x, y) *
        shape.multiplier - 1
end

-- One coin flip may bend the silhouette with two independent, broad
-- simplex offsets. The cave-edge field itself remains undistorted.
local function choose_distortion(builder)
    if not builder:one_in(2) then
        return nil
    end

    local scale = subdivision.range(builder, 5, 20)
    local offset_x = noise.simplex(builder,
        subdivision.real(builder, 0.01, 0.2), true)
    local offset_y = noise.simplex(builder,
        subdivision.real(builder, 0.01, 0.2), true)

    return {
        scale = scale,
        x = offset_x,
        y = offset_y,
    }
end

-- A high-frequency simplex ridge or a Worley difference roughens the
-- chosen silhouette; both choices come from the source's equal coin flip.
local function choose_cave_edge(builder)
    if builder:one_in(2) then
        return {
            kind = "simplex",
            field = noise.simplex(builder,
                subdivision.real(builder, 0.8, 2), true),
        }
    end

    return {
        kind = "worley",
        field = noise.worley(builder,
            subdivision.real(builder, 0.3, 0.8)),
    }
end

-- Source simplex ridges use abs(2v-1); Worley already returns the
-- nearest-feature difference needed for cave-like edge variation.
local function cave_edge_value(edge, x, y)
    if edge.kind == "simplex" then
        return math.abs(noise.simplex_at(edge.field, x, y) * 2 - 1)
    end

    return noise.worley_at(edge.field, x, y)
end

-- Only the broad shape receives domain distortion. The border and cave
-- edge are evaluated at the original cell, as in the source render field.
local function paint(builder, shape, distortion, edge, limit)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            local shaped_x = x
            local shaped_y = y

            if distortion then
                shaped_x = x + noise.simplex_at(distortion.x, x, y) *
                    distortion.scale
                shaped_y = y + noise.simplex_at(distortion.y, x, y) *
                    distortion.scale
            end

            local value = shape_value(shape, shaped_x, shaped_y) +
                noise.border(x, y, 5, false) +
                cave_edge_value(edge, x, y)

            if value < limit then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Source chooses width before silhouette, then distortion and cave edge.
-- Region cleanup leaves one playable cave for the shared stair owner.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local width = subdivision.range(builder, 10, 20)
    local shape = choose_shape(builder, width)
    local distortion = choose_distortion(builder)
    local edge = choose_cave_edge(builder)
    local limit = subdivision.real(builder, 0.65, 0.9)

    paint(builder, shape, distortion, edge, limit)
    regions.keep_largest_region(builder)
    material.caves(builder, api)

    return { builder = builder }
end

return layout
