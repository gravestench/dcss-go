-- Theory of operation: Grid Shapes divides a padded Snake or Pan map into
-- cells, then paints a broad container shape around each cell. Some cells
-- receive a smaller rock core, leaving shaped corridors between them.
-- Snake always adds cellular cave noise; Pan does so on half its floors.
-- The source's shape field is chosen once for the floor and reused by its
-- render calls, even though later unused shape selections are made.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local cell_graph = require("policy.generation.layouts.cell_graph")
local noise = require("policy.generation.layouts.procedural_noise")
local material = require("policy.generation.layouts.material")

local layout = {}

local circle = 1
local octagon = 2
local diamond = 3
local hexagon = 4
local triangle = 5

-- The source gives each of its five primitive functions equal weight.
-- Its triangle primitive independently flips vertically when selected.
local function choose_shape(builder)
    local kind = builder:roll(5) + 1

    return {
        kind = kind,
        flip = kind == triangle and builder:one_in(2),
    }
end

-- Evaluate the source primitive after its translate-by-one and half-size
-- scale. Values at or below one belong to the painted shape.
local function shape_value(shape, x, y, width, height)
    local nx = 2 * x / width - 1
    local ny = 2 * y / height - 1
    local ax = math.abs(nx)
    local ay = math.abs(ny)

    if shape.kind == circle then
        return math.sqrt(nx * nx + ny * ny)
    elseif shape.kind == octagon then
        return math.max(ax, ay, ax + ay - 0.25)
    elseif shape.kind == diamond then
        return ax + ay
    elseif shape.kind == hexagon then
        local shifted_y = ay + 0.5

        return math.max(ax, shifted_y, ax + ay)
    end

    if shape.flip then
        ny = -ny
    end

    return math.max(ny, -(nx + ny), nx - ny)
end

-- Source render_map_area leaves outside cells untouched. The cavey variant
-- adds one quarter of a stable Worley difference at global map coordinates.
local function paint(builder, shape, field, bounds, glyph)
    local width = bounds.x2 - bounds.x1 + 1
    local height = bounds.y2 - bounds.y1 + 1

    if width <= 0 or height <= 0 then
        return
    end

    for y = math.max(1, bounds.y1), math.min(grid.height - 2, bounds.y2) do
        for x = math.max(1, bounds.x1), math.min(grid.width - 2, bounds.x2) do
            local value = shape_value(shape,
                x - bounds.x1, y - bounds.y1, width, height)

            if field then
                value = value + noise.worley_at(field, x, y) / 4
            end

            if value <= 1 then
                builder:set(x, y, glyph)
            end
        end
    end
end

-- Each cell's corridor is limited by its shortest dimension and the
-- floor's sampled maximum. Small cells therefore retain thin passages.
local function corridor_width(cell, maximum)
    local width = cell.x2 - cell.x1 + 1
    local height = cell.y2 - cell.y1 + 1

    return math.min(math.floor(math.min(width, height) / 4),
        math.floor(maximum / 2))
end

-- Paint the large container before the optional central rock column.
-- The source fills a core with probability 0.5 plus its relative cell size.
local function paint_cells(builder, cells, shape, field, maximum)
    for _, cell in ipairs(cells) do
        local corridor = corridor_width(cell, maximum)
        local width = cell.x2 - cell.x1 + 1
        local height = cell.y2 - cell.y1 + 1

        paint(builder, shape, field, {
            x1 = cell.x1 - corridor,
            y1 = cell.y1 - corridor,
            x2 = cell.x2 + corridor,
            y2 = cell.y2 + corridor,
        }, ".")

        local fill_chance = 0.5 +
            math.max(width, height) / (math.max(grid.width, grid.height) * 2)

        if builder:roll(1000000) / 1000000 < fill_chance then
            paint(builder, shape, field, {
                x1 = cell.x1 + corridor,
                y1 = cell.y1 + corridor,
                x2 = cell.x2 - corridor,
                y2 = cell.y2 - corridor,
            }, "x")
        end
    end
end

-- Preserve the source's branch choice and padded subdivision. The shared
-- region pass removes islands before normal stairs claim the surviving floor.
function layout.layout_grid_shapes(api)
    local builder = grid.new(api.ctx)
    local cavey = api.branch == "Snake" or
        (api.branch == "Pan" and builder:one_in(2))
    local minimum_corridor = cavey and 4 or 2
    local maximum_corridor = subdivision.range(builder,
        minimum_corridor, 10)
    local maximum_pad = maximum_corridor +
        subdivision.range(builder, 1, 6)
    local options = {
        guaranteed_divides = 2,
        initial_chance = 100,
        multiplier = 0.9,
        minimum_size_x = 8,
        minimum_size_y = 8,
    }
    local cells = subdivision.partition(builder, options,
        maximum_corridor, maximum_pad)
    local shape = choose_shape(builder)
    local field

    if cavey then
        field = noise.worley(builder, 0.5)
    end

    paint_cells(builder, cells, shape, field, maximum_corridor)
    cell_graph.keep_largest_region(builder)

    if cavey then
        material.caves(builder, api)
    else
        material.level(builder, api)
    end

    if builder.bad_random then
        error("Grid Shapes could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        cells = cells,
        cavey = cavey,
    }
end

return layout
