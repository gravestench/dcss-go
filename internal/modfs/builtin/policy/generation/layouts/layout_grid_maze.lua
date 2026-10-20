-- Theory of operation: Grid Maze subdivides a padded inner rectangle into
-- small cells, connects their shared edges until its regions meet, then
-- optionally breaks extra walls. Closed edges become thin Dungeon walls or
-- thicker branch walls; some connections carry doors. The final zonifier
-- keeps only the main playable region before stairs are placed.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local cell_graph = require("policy.generation.layouts.cell_graph")
local material = require("policy.generation.layouts.material")

local layout = {}

-- Source grid options depend on the per-floor thin-wall choice. Dungeon
-- forces thin walls after the initial rarity draw, while Snake forces thick.
local function grid_options(builder, branch)
    local thin = builder:one_in(3)
    local detree = builder:chance_in(9, 10)
    local doors = builder:chance_in(2, 3)

    if branch == "D" then
        thin = true
    elseif branch == "Snake" or branch == "Lair" then
        thin = false
    end

    local minimum = subdivision.range(builder, thin and 3 or 4,
        thin and 5 or 6)

    return {
        thin = thin,
        detree = detree,
        doors = doors,
        partition = {
            guaranteed_divides = 5,
            initial_chance = 100,
            multiplier = subdivision.real(builder, 0.97, 0.99),
            minimum_size_x = minimum,
            minimum_size_y = minimum,
        },
    }
end

-- Run the named DES hook through the shared cell graph. Returned cells and
-- edges make source geometry inspectable without a second Go selector.
function layout.layout_grid_maze(api)
    local builder = grid.new(api.ctx)
    local options = grid_options(builder, api.branch)
    local cells = subdivision.partition(builder, options.partition, 2, 10)
    local edges = cell_graph.edges(cells)
    local minimum_border = options.thin and 2 or 3
    local extra = 0

    if options.detree then
        extra = subdivision.range(builder,
            math.ceil(#cells / 20), math.floor(#cells / 5))
    end

    cell_graph.connect(builder, edges, #cells, minimum_border,
        options.doors, extra)
    cell_graph.paint(builder, cells, edges, options.thin)

    if api.branch == "Tar" then
        cell_graph.fortify(builder, edges)
    end

    cell_graph.keep_largest_region(builder)
    material.level(builder, api)

    if builder.bad_random then
        error("grid maze random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
        edges = edges,
    }
end

return layout
