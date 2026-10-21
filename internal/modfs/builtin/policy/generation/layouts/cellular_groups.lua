-- Theory of operation: source omnigrid gives every partition cell a tile
-- and merges cardinally touching cells of the same tile into a group.
-- Diagonal contacts influence growth weights but never merge groups.
-- Candidate traversal stays in source cell order so hash iteration cannot
-- change a seeded map when an unrelated definition is added.
local groups = {}
groups.__index = groups

-- Diagonal neighbors touch at exactly one corner. Cardinal neighbors are
-- supplied separately by the existing shared-edge graph.
local function touches_corner(first, second)
    local x_touch = first.x2 + 1 == second.x1 or
        second.x2 + 1 == first.x1
    local y_touch = first.y2 + 1 == second.y1 or
        second.y2 + 1 == first.y1

    return x_touch and y_touch
end

-- Source cell.edges contains every side on the padded partition boundary.
-- Growing walls use that count to keep the enclosing region connected.
local function boundary_sides(cell, bounds)
    local count = 0

    if cell.x1 == bounds.x1 then
        count = count + 1
    end

    if cell.x2 == bounds.x2 then
        count = count + 1
    end

    if cell.y1 == bounds.y1 then
        count = count + 1
    end

    if cell.y2 == bounds.y2 then
        count = count + 1
    end

    return count
end

-- Follow merged group ownership without changing a cell's stable index.
local function root(owner, index)
    while owner[index] ~= index do
        index = owner[index]
    end

    return index
end

-- Keep the earliest cell as a stable group ID while preserving group size
-- for Gridlike's inverse-size room weight.
local function merge(owner, sizes, first, second)
    local left = root(owner, first)
    local right = root(owner, second)

    if left == right then
        return
    end

    local keep = math.min(left, right)
    local joined = math.max(left, right)

    owner[joined] = keep
    sizes[keep] = sizes[keep] + sizes[joined]
end

-- Build both adjacency views once. Shared edges supply cardinal contacts;
-- corner contacts are added only to the broader near view.
function groups.new(cells, edges, bounds)
    local direct = {}
    local near = {}
    local owner = {}
    local sizes = {}
    local boundaries = {}

    for index, cell in ipairs(cells) do
        direct[index] = {}
        near[index] = {}
        owner[index] = index
        sizes[index] = 1
        boundaries[index] = boundary_sides(cell, bounds)
    end

    for _, edge in ipairs(edges) do
        direct[edge.first][#direct[edge.first] + 1] = edge.second
        direct[edge.second][#direct[edge.second] + 1] = edge.first
        near[edge.first][#near[edge.first] + 1] = edge.second
        near[edge.second][#near[edge.second] + 1] = edge.first
    end

    for first = 1, #cells do
        for second = first + 1, #cells do
            if touches_corner(cells[first], cells[second]) then
                near[first][#near[first] + 1] = second
                near[second][#near[second] + 1] = first
            end
        end
    end

    return setmetatable({
        cells = cells,
        direct = direct,
        near = near,
        owner = owner,
        sizes = sizes,
        boundaries = boundaries,
    }, groups)
end

-- Count distinct neighboring groups and their touching cells. The caller
-- chooses cardinal-only or cardinal-plus-diagonal contacts and an optional
-- tile filter, matching source count_adjacent without retaining border data.
function groups:adjacent(index, tile, diagonals)
    local contacts = diagonals and self.near[index] or self.direct[index]
    local track = {}
    local count = 0

    for _, neighbor_index in ipairs(contacts) do
        local neighbor = self.cells[neighbor_index]

        if neighbor.tile and (not tile or neighbor.tile == tile) then
            local id = root(self.owner, neighbor_index)

            if not track[id] then
                track[id] = 0
                count = count + 1
            end

            track[id] = track[id] + 1
        end
    end

    return count, track
end

-- A group size is the count of cardinally joined source cells, not the
-- number of sides touching the current candidate.
function groups:size(id)
    return self.sizes[root(self.owner, id)]
end

-- Read the source boundary count for weighted wall seeds and growth.
function groups:edge_count(index)
    return self.boundaries[index]
end

-- A chosen tile joins all adjacent cells that already carry that tile.
function groups:place(index, tile)
    self.cells[index].tile = tile

    for _, neighbor in ipairs(self.direct[index]) do
        if self.cells[neighbor].tile == tile then
            merge(self.owner, self.sizes, index, neighbor)
        end
    end
end

-- One weighted source-order draw selects an unassigned cell. A nil result
-- means the tile has no currently eligible candidate.
function groups:choose(builder, tile, weight_for)
    local weights = {}
    local total = 0

    for index, cell in ipairs(self.cells) do
        local value = 0

        if not cell.tile then
            value = weight_for(self, index, tile)
        end

        weights[index] = value
        total = total + value
    end

    if total == 0 then
        return nil
    end

    local draw = builder:roll(total)

    for index, value in ipairs(weights) do
        if draw < value then
            return index
        end

        draw = draw - value
    end
end

return groups
