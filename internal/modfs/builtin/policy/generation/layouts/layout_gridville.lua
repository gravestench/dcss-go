-- Theory of operation: Gridville divides a padded floor into small cells,
-- grows scattered groups of buildings and walls, then paints each building
-- as a hollow box. Borders between buildings become open links or doors;
-- the shared region pass retains the connected playable part of the city.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local cell_graph = require("policy.generation.layouts.cell_graph")
local cell_tiles = require("policy.generation.layouts.cell_tiles")
local material = require("policy.generation.layouts.material")

local layout = {}

-- Use the source size range for both axes. Maximum size forces further
-- division so the first city seeds can spread across many short blocks.
local function partition_options(builder)
    local minimum = subdivision.range(builder, 4, 5)
    local maximum = subdivision.range(builder, minimum, 10)

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

-- Paint a city cell's walls and walkable interior. Untiled wall cells stay
-- as the builder's original rock, while open floors are filled separately.
local function paint_cells(builder, cells, group_of, room_materials, branch)
    local group_material = {}

    for index, cell in ipairs(cells) do
        if cell.tile == "floor" then
            for y = cell.y1, cell.y2 do
                for x = cell.x1, cell.x2 do
                    builder:set(x, y, ".")
                end
            end
        elseif cell.tile == "city" then
            local group = group_of(index)

            if room_materials and not group_material[group] then
                group_material[group] = material.room(builder, branch)
            end

            local wall = group_material[group] or "#"

            for y = cell.y1, cell.y2 do
                for x = cell.x1, cell.x2 do
                    local border = x == cell.x1 or x == cell.x2 or
                        y == cell.y1 or y == cell.y2

                    builder:set(x, y, border and wall or ".")
                end
            end
        end
    end
end

-- Find the strip on a particular cell's side of a shared edge. Adjacent
-- cells have separate boundary coordinates, as in the original omnigrid.
local function side(edge, cell)
    if edge.orientation == "vertical" then
        local x = cell.x2 == edge.x1 and edge.x1 or edge.x2

        return x, edge.y1, x, edge.y2
    end

    local y = cell.y2 == edge.y1 and edge.y1 or edge.y2

    return edge.x1, y, edge.x2, y
end

-- Clear a border without removing its corner stones. Short borders cannot
-- fit a passage in the source unless a layout explicitly enables them.
local function clear_side(builder, edge, cell)
    local x1, y1, x2, y2 = side(edge, cell)

    if edge.orientation == "vertical" then
        for y = y1 + 1, y2 - 1 do
            builder:set(x1, y, ".")
        end
    else
        for x = x1 + 1, x2 - 1 do
            builder:set(x, y1, ".")
        end
    end
end

-- The source names this a midpoint but picks a random interior border
-- position. One shared draw aligns door and opening on opposite sides.
local function doorway(builder, edge)
    return subdivision.range(builder, 1, edge.length - 2)
end

-- Place one door on a city's boundary at the selected interior offset.
local function door_on_side(builder, edge, cell, offset)
    local x1, y1 = side(edge, cell)

    if edge.orientation == "vertical" then
        builder:set(x1, y1 + offset, "+")
    else
        builder:set(x1 + offset, y1, "+")
    end
end

-- Carve each shared city border once. Building-to-building links open on
-- both sides, or put a door on one side and a clear passage on the other.
-- A building next to untiled rock clears only its own boundary, matching
-- the source's distinction between wall and outside-floor neighbors.
local function paint_edges(builder, cells, edges)
    for _, edge in ipairs(edges) do
        local first = cells[edge.first]
        local second = cells[edge.second]
        local first_city = first.tile == "city"
        local second_city = second.tile == "city"

        if first_city and second_city and edge.length >= 3 then
            local offset = doorway(builder, edge)

            if builder:chance_in(2, 3) then
                clear_side(builder, edge, first)
                clear_side(builder, edge, second)
            elseif builder:one_in(2) then
                door_on_side(builder, edge, first, offset)
                clear_side(builder, edge, second)
            else
                clear_side(builder, edge, first)
                door_on_side(builder, edge, second, offset)
            end
        elseif first_city or second_city then
            local city = first_city and first or second
            local other = first_city and second or first

            if other.tile == "wall" then
                clear_side(builder, edge, city)
            elseif edge.length >= 3 then
                door_on_side(builder, edge, city, doorway(builder, edge))
            end
        end
    end
end

-- Source Gridville removes many extra doors after carving, using an
-- adjacent wall type so surviving doors remain the deliberate exceptions.
local function trim_doors(builder)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            if builder:cell(x, y) == "+" and builder:chance_in(3, 5) then
                local replacement = builder:cell(x + 1, y)

                if replacement == "." then
                    replacement = builder:cell(x, y + 1)
                end

                builder:set(x, y, replacement)
            end
        end
    end
end

-- Run the checked-in DES hook with source tile probabilities and render its
-- typed rows for the shared Dungeon terrain decoder and stair placement.
function layout.layout_gridville(api)
    local builder = grid.new(api.ctx)
    local open = not builder:one_in(4)
    local room_materials = open and builder:one_in(3)
    local cells, bounds = subdivision.partition(builder,
        partition_options(builder), 2, 8)
    local edges = cell_graph.edges(cells)
    local seeds = 1

    if open then
        seeds = subdivision.range(builder,
            math.ceil(#cells / 50), math.ceil(#cells / 10))
    end

    local group_of = cell_tiles.gridville(builder, cells, edges, bounds, seeds)

    for _, cell in ipairs(cells) do
        if not cell.tile then
            cell.tile = open and "floor" or "wall"
        end
    end

    paint_cells(builder, cells, group_of, room_materials, api.branch)
    paint_edges(builder, cells, edges)
    trim_doors(builder)
    cell_graph.keep_largest_region(builder)

    if not room_materials then
        material.level(builder, api)
    end

    if builder.bad_random then
        error("Gridville random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
        edges = edges,
        open = open,
    }
end

return layout
