-- Source cellular layouts assign tiles to omnigrid cells, then merge cells
-- of the same tile across shared borders. This owner keeps group identity
-- and adjacency rules separate from Gridville's city-specific painting.
local tiles = {}

-- Two cells that touch only at a corner are near enough to affect seed and
-- growth eligibility, but do not merge into one traversable group.
local function corner_neighbors(first, second)
    local x_touch = first.x2 + 1 == second.x1 or second.x2 + 1 == first.x1
    local y_touch = first.y2 + 1 == second.y1 or second.y2 + 1 == first.y1

    return x_touch and y_touch
end

-- Build stable cardinal and diagonal adjacency lists once from the source
-- subdivision cells; no Lua hash traversal enters random candidate order.
local function neighbors(cells, edges)
    local direct = {}
    local near = {}

    for index = 1, #cells do
        direct[index] = {}
        near[index] = {}
    end

    for _, edge in ipairs(edges) do
        direct[edge.first][#direct[edge.first] + 1] = edge.second
        direct[edge.second][#direct[edge.second] + 1] = edge.first
        near[edge.first][#near[edge.first] + 1] = edge.second
        near[edge.second][#near[edge.second] + 1] = edge.first
    end

    for first = 1, #cells do
        for second = first + 1, #cells do
            if corner_neighbors(cells[first], cells[second]) then
                near[first][#near[first] + 1] = second
                near[second][#near[second] + 1] = first
            end
        end
    end

    return direct, near
end

-- Find one mutable tile group. The original cell index remains stable while
-- a neighboring same-type tile joins it.
local function root(owner, index)
    while owner[index] ~= index do
        index = owner[index]
    end

    return index
end

-- Source tilepick joins all adjacent cells with the chosen tile. The root
-- is the earliest cell index for deterministic material assignment.
local function merge(owner, first, second)
    local left = root(owner, first)
    local right = root(owner, second)

    if left ~= right then
        owner[math.max(left, right)] = math.min(left, right)
    end
end

-- Count distinct neighboring groups, optionally restricting their tile.
-- Diagonal contacts matter for eligibility but cannot join a group.
local function group_count(cells, owner, list, tile)
    local seen = {}
    local count = 0

    for _, index in ipairs(list) do
        local neighbor = cells[index]

        if neighbor.tile and (not tile or neighbor.tile == tile) then
            local id = root(owner, index)

            if not seen[id] then
                seen[id] = true
                count = count + 1
            end
        end
    end

    return count
end

-- Exactly one side on the padded outer boundary makes a wall seed eligible
-- even when no other wall group exists yet.
local function one_outer_edge(cell, bounds)
    local edges = 0

    if cell.x1 == bounds.x1 then
        edges = edges + 1
    end

    if cell.x2 == bounds.x2 then
        edges = edges + 1
    end

    if cell.y1 == bounds.y1 then
        edges = edges + 1
    end

    if cell.y2 == bounds.y2 then
        edges = edges + 1
    end

    return edges == 1
end

-- Place one tile and merge it with cardinal neighbors of the same type.
local function place(cells, owner, direct, index, tile)
    cells[index].tile = tile

    for _, adjacent in ipairs(direct[index]) do
        if cells[adjacent].tile == tile then
            merge(owner, index, adjacent)
        end
    end
end

-- Draw a cell from positive weights in source index order. A nil result
-- ends tilepick when no cell can satisfy its neighbor constraints.
local function weighted_cell(builder, weights)
    local total = 0

    for _, weight in ipairs(weights) do
        total = total + weight
    end

    if total == 0 then
        return nil
    end

    local draw = builder:roll(total)

    for index, weight in ipairs(weights) do
        if draw < weight then
            return index
        end

        draw = draw - weight
    end
end

-- A first city seed avoids both bordering and diagonal existing groups.
-- This scatters initial buildings instead of making one dense cluster.
local function seed_weights(cells, owner, near)
    local weights = {}

    for index, cell in ipairs(cells) do
        if not cell.tile and group_count(cells, owner, near[index]) == 0 then
            weights[index] = 10
        else
            weights[index] = 0
        end
    end

    return weights
end

-- Source growth requires exactly one nearby group of the chosen tile and
-- exactly one cardinal group that it will touch. Wall may seed an outer edge.
local function growth_weights(cells, owner, direct, near, bounds, tile)
    local weights = {}

    for index, cell in ipairs(cells) do
        local weight = 0

        if not cell.tile then
            local nearby = group_count(cells, owner, near[index], tile)

            if tile == "wall" and nearby == 0 and one_outer_edge(cell, bounds) then
                weight = 5
            elseif nearby == 1 then
                local adjacent_tile = tile == "wall" and tile or nil
                local adjacent = group_count(cells, owner, direct[index], adjacent_tile)

                if adjacent == 1 then
                    weight = 10
                end
            end
        end

        weights[index] = weight
    end

    return weights
end

-- Return the source's city/wall tiling and a stable group accessor for
-- per-group materials. Unassigned cells remain for the caller's floor rule.
function tiles.gridville(builder, cells, edges, bounds, seeds)
    local direct, near = neighbors(cells, edges)
    local owner = {}

    for index = 1, #cells do
        owner[index] = index
    end

    for _ = 1, seeds do
        local index = weighted_cell(builder, seed_weights(cells, owner, near))

        if not index then
            break
        end

        place(cells, owner, direct, index, "city")
    end

    for _ = 1, 500 do
        local tile = builder:roll(4) == 0 and "wall" or "city"
        local weights = growth_weights(cells, owner, direct, near, bounds, tile)
        local index = weighted_cell(builder, weights)

        if not index then
            break
        end

        place(cells, owner, direct, index, tile)
    end

    return function(index)
        return root(owner, index)
    end
end

return tiles
