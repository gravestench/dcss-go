-- Theory of operation: Stronghold subdivides a padded region, joins some
-- interior cells into building clusters, and paints every other cell as a
-- street. Cluster cells become hollow, variably walled boxes. Source door
-- passes connect adjacent rooms before detached regions are filled in.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local cell_graph = require("policy.generation.layouts.cell_graph")
local groups = require("policy.generation.layouts.stronghold_groups")
local material = require("policy.generation.layouts.material")

local layout = {}

-- The source forces eight divisions, then reduces its split chance slowly
-- enough for clusters of small cells to form across the padded center.
local function partition_options(builder)
    local minimum = subdivision.range(builder, 3, 6)

    return {
        guaranteed_divides = 8,
        initial_chance = 100,
        multiplier = subdivision.real(builder, 0.95, 0.97),
        minimum_size_x = minimum,
        minimum_size_y = minimum,
    }
end

-- Fill a source cell with either a hollow building or open street. A
-- group material is shared across its joined members, not picked per cell.
local function paint_cell(builder, cell, wall)
    for y = cell.y1, cell.y2 do
        for x = cell.x1, cell.x2 do
            local boundary = x == cell.x1 or x == cell.x2 or
                y == cell.y1 or y == cell.y2
            local glyph = cell.building and boundary and wall or "."

            builder:set(x, y, glyph)
        end
    end
end

-- Ungrouped street cells have a four-in-five chance of containing one
-- rock block, leaving at least one open cell around its chosen rectangle.
local function street_block(builder, cell)
    if not builder:chance_in(4, 5) then
        return
    end

    local width = cell.x2 - cell.x1 + 1
    local height = cell.y2 - cell.y1 + 1
    local block_width = subdivision.range(builder, 1, width - 2)
    local block_height = subdivision.range(builder, 1, height - 2)
    local x1 = subdivision.range(builder, cell.x1 + 1,
        cell.x2 - block_width)
    local y1 = subdivision.range(builder, cell.y1 + 1,
        cell.y2 - block_height)

    for y = y1, y1 + block_height - 1 do
        for x = x1, x1 + block_width - 1 do
            builder:set(x, y, "#")
        end
    end
end

-- Paint all cells before opening connected borders so a later neighboring
-- box cannot overwrite a passage carved by an earlier one.
local function paint_cells(builder, cells, group_of)
    for index, cell in ipairs(cells) do
        local group = group_of(index)

        paint_cell(builder, cell, group.material or "#")

        if not cell.building then
            street_block(builder, cell)
        end
    end
end

-- Locate the one-cell boundary strip on a specific side of a shared edge.
local function side(edge, cell)
    if edge.orientation == "vertical" then
        local x = cell.x2 == edge.x1 and edge.x1 or edge.x2

        return x, edge.y1
    end

    local y = cell.y2 == edge.y1 and edge.y1 or edge.y2

    return edge.x1, y
end

-- Remove only the straight interior of a building border. Its end stones
-- remain intact so adjacent partitions do not dissolve into open squares.
local function open_side(builder, edge, cell)
    local x1, y1 = side(edge, cell)

    if edge.orientation == "vertical" then
        for y = edge.y1 + 1, edge.y2 - 1 do
            builder:set(x1, y, ".")
        end
    else
        for x = edge.x1 + 1, edge.x2 - 1 do
            builder:set(x, y1, ".")
        end
    end
end

-- Most internal links open on both sides. The source leaves one wall side
-- closed on a quarter of links, creating partitions for the door passes.
local function open_links(builder, cells, edges)
    for _, edge in ipairs(edges) do
        if edge.style == "internal" then
            local first = cells[edge.first]
            local second = cells[edge.second]

            if builder:one_in(4) then
                if builder:one_in(2) then
                    open_side(builder, edge, first)
                else
                    open_side(builder, edge, second)
                end
            else
                open_side(builder, edge, first)
                open_side(builder, edge, second)
            end
        end
    end
end

-- A candidate wall cell joins floors on opposing sides. Before adding
-- another door nearby, the source checks that the wall stays uninterrupted
-- along both directions for the requested distance.
local function wall_is_empty(builder, x, y, horizontal, distance)
    local step_x = horizontal and 1 or 0
    local step_y = horizontal and 0 or 1
    local normal_x = horizontal and 0 or 1
    local normal_y = horizontal and 1 or 0

    for _, sign in ipairs({ 1, -1 }) do
        for offset = 1, distance do
            local check_x = x + sign * offset * step_x
            local check_y = y + sign * offset * step_y
            local plus_x = check_x + normal_x
            local plus_y = check_y + normal_y
            local minus_x = check_x - normal_x
            local minus_y = check_y - normal_y

            if not builder:inside({ x = plus_x, y = plus_y }) or
                not builder:inside({ x = minus_x, y = minus_y }) or
                builder:cell(plus_x, plus_y) ~= "." or
                builder:cell(minus_x, minus_y) ~= "." then
                break
            end

            local glyph = builder:cell(check_x, check_y)

            if glyph ~= "#" and glyph ~= "c" and
                glyph ~= "v" and glyph ~= "b" then
                return false
            end
        end
    end

    return true
end

-- Each source door pass visits a bounded number of unique random cells.
-- The second pass requires a three-cell wall gap around its extra doors.
local function add_doors(builder, minimum, maximum, distance)
    local candidates = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            candidates[#candidates + 1] = { x = x, y = y }
        end
    end

    local checks = subdivision.range(builder, minimum, maximum)

    for index = 1, checks do
        local chosen = index + builder:roll(#candidates - index + 1)

        candidates[index], candidates[chosen] =
            candidates[chosen], candidates[index]

        local point = candidates[index]
        local x = point.x
        local y = point.y
        local glyph = builder:cell(x, y)

        if glyph == "#" or glyph == "c" or glyph == "v" or glyph == "b" then
            local vertical = builder:cell(x, y - 1) == "." and
                builder:cell(x, y + 1) == "." and
                wall_is_empty(builder, x, y, true, distance)
            local horizontal = builder:cell(x - 1, y) == "." and
                builder:cell(x + 1, y) == "." and
                wall_is_empty(builder, x, y, false, distance)

            if vertical or horizontal then
                builder:set(x, y, "+")
            end
        end
    end
end

-- Execute the source DES hook with grouped buildings, incidental doors,
-- and the same connected-region cleanup used by other cell layouts.
function layout.layout_stronghold(api)
    local builder = grid.new(api.ctx)
    local options = partition_options(builder)
    local cells, bounds = subdivision.partition(builder,
        options, 2, 10)
    local edges = cell_graph.edges(cells)
    local room_materials = builder:one_in(3)
    local group_of = groups.connect(builder, cells, edges,
        bounds, room_materials, api.branch)

    paint_cells(builder, cells, group_of)
    open_links(builder, cells, edges)
    add_doors(builder, 100, 400, 9999)
    add_doors(builder, 0, 400, 3)
    cell_graph.keep_largest_region(builder)

    if not room_materials then
        material.level(builder, api)
    end

    if builder.bad_random then
        error("Stronghold random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
        edges = edges,
    }
end

return layout
