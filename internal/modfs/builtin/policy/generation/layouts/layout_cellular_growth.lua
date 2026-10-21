-- Theory of operation: source Cellular Growth first seeds separated rock
-- groups inside an irregular omnigrid. A second pass adds cells only where
-- cardinal and diagonal group rules permit growth. Unassigned cells open
-- into floor, and the shared region pass removes isolated floor pockets.
local grid = require("policy.generation.grid")
local subdivision = require("policy.generation.layouts.subdivision")
local edges = require("policy.generation.layouts.cell_graph")
local groups = require("policy.generation.layouts.cellular_groups")
local material = require("policy.generation.layouts.material")

local layout = {}

-- The source chooses a tight maximum size but a smaller minimum so its
-- automaton grows across many uneven partition cells.
local function partition_options(builder)
    local maximum = subdivision.range(builder, 5, 8)
    local minimum = subdivision.range(builder, 3, 4)

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

-- Initial wall seeds prefer the padded edge. Interior seeds cannot touch
-- any existing group, even diagonally, so they remain separate islands.
local function seed_weight(tiling, index)
    if tiling:edge_count(index) > 0 then
        return 20
    end

    local nearby = tiling:adjacent(index, nil, true)

    return nearby == 0 and 10 or 0
end

-- The source chooses one of three growth styles: narrow strands, spreading
-- thin walls, or broad blobs. Edge candidates follow their own linking rule.
local function growth_weight(tiling, index, method)
    local nearby = tiling:adjacent(index, nil, true)
    local direct, touches = tiling:adjacent(index, nil, false)
    local edge_count = tiling:edge_count(index)

    if edge_count > 0 then
        if nearby == 0 then
            return 2
        end

        if nearby == direct then
            for _, neighbor in ipairs(tiling.direct[index]) do
                if tiling:edge_count(neighbor) == 0 then
                    return 0
                end
            end

            return 20
        end
    end

    if nearby ~= 1 or direct ~= 1 or edge_count > 0 then
        return 0
    end

    for _, contacts in pairs(touches) do
        if method == 0 then
            return contacts == 1 and 10 or 0
        elseif method == 1 then
            return math.ceil(100 / contacts)
        end

        return 10
    end

    return 0
end

-- A source tilepick attempt chooses one eligible cell. Stop early when no
-- candidates remain; drawing another zero-weight cell cannot change a map.
local function grow(builder, tiling, limit, weight_for)
    for _ = 1, limit do
        local index = tiling:choose(builder, "wall", weight_for)

        if not index then
            break
        end

        tiling:place(index, "wall")
    end
end

-- The source leaves all wall cells as original rock and clears only cells
-- not claimed by the automaton. Region cleanup retains traversable floor.
local function paint_floor(builder, cells)
    for _, cell in ipairs(cells) do
        if cell.tile ~= "wall" then
            for y = cell.y1, cell.y2 do
                for x = cell.x1, cell.x2 do
                    builder:set(x, y, ".")
                end
            end
        end
    end

    edges.keep_largest_region(builder)
end

-- The DES hook returns real terrain; catalog.execute owns stair placement
-- and branch selection. Cell groups stay local to this one generated floor.
local function layout_cellular_growth(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local cells, bounds = subdivision.partition(builder,
        partition_options(builder), 2, 10)
    local tiling = groups.new(cells, edges.edges(cells), bounds)
    local seeds = subdivision.range(builder, 1, 20)

    grow(builder, tiling, seeds, seed_weight)

    local method = builder:roll(3)

    -- Bind one source growth style to every candidate weight on this floor.
    grow(builder, tiling, 1000, function(state, index)
        return growth_weight(state, index, method)
    end)
    paint_floor(builder, cells)
    material.level(builder, api)

    if builder.bad_random then
        error("Cellular Growth random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        cells = cells,
    }
end

layout.layout_cellular_growth = layout_cellular_growth

return layout
