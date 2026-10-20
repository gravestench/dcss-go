-- Omnigrid cell layouts need a graph of shared edges after subdivision.
-- One edge joins two cells that share a horizontal or vertical boundary;
-- the graph owns connectivity while each layout chooses its door policy.
local grid = require("policy.generation.grid")

local graph = {}

-- Record the overlapping segment where two cells meet along an x boundary.
local function vertical_edge(first, second, first_index, second_index)
    local left = first
    local right = second

    if second.x2 + 1 == first.x1 then
        left = second
        right = first
    elseif first.x2 + 1 ~= second.x1 then
        return nil
    end

    local top = math.max(left.y1, right.y1)
    local bottom = math.min(left.y2, right.y2)

    if top > bottom then
        return nil
    end

    return {
        first = first_index,
        second = second_index,
        orientation = "vertical",
        x1 = left.x2,
        x2 = right.x1,
        y1 = top,
        y2 = bottom,
        length = bottom - top + 1,
    }
end

-- Record the overlapping segment where two cells meet along a y boundary.
local function horizontal_edge(first, second, first_index, second_index)
    local upper = first
    local lower = second

    if second.y2 + 1 == first.y1 then
        upper = second
        lower = first
    elseif first.y2 + 1 ~= second.y1 then
        return nil
    end

    local left = math.max(upper.x1, lower.x1)
    local right = math.min(upper.x2, lower.x2)

    if left > right then
        return nil
    end

    return {
        first = first_index,
        second = second_index,
        orientation = "horizontal",
        x1 = left,
        x2 = right,
        y1 = upper.y2,
        y2 = lower.y1,
        length = right - left + 1,
    }
end

-- Pairwise comparison is small for one floor and avoids retaining a second
-- mutable border object on every cell in the Lua ruleset.
function graph.edges(cells)
    local edges = {}

    for first = 1, #cells do
        for second = first + 1, #cells do
            local edge = vertical_edge(cells[first], cells[second], first, second) or
                horizontal_edge(cells[first], cells[second], first, second)

            if edge then
                edges[#edges + 1] = edge
            end
        end
    end

    return edges
end

-- One weighted draw is shared by group, cell, and border selection. Stable
-- candidate order makes result seeds independent of Lua table iteration.
local function weighted_pick(builder, candidates)
    local total = 0

    for _, candidate in ipairs(candidates) do
        total = total + candidate.weight
    end

    if total == 0 then
        return nil
    end

    local draw = builder:roll(total)

    for _, candidate in ipairs(candidates) do
        if draw < candidate.weight then
            return candidate.value
        end

        draw = draw - candidate.weight
    end
end

-- Build the source-style mutable groups and incident borders once. A cell
-- keeps its original index even after another group absorbs it.
local function initial_groups(edges, cell_count)
    local groups = {}
    local owner = {}
    local incident = {}

    for index = 1, cell_count do
        groups[index] = { index }
        owner[index] = index
        incident[index] = {}
    end

    for _, edge in ipairs(edges) do
        incident[edge.first][#incident[edge.first] + 1] = edge
        incident[edge.second][#incident[edge.second] + 1] = edge
    end

    return groups, owner, incident
end

-- Source connect weights a group inversely by its size, then a cell by its
-- number of still-unselected borders. That favors spreading the maze.
local function choose_group_cell(builder, groups, incident)
    local choices = {}

    for index, members in ipairs(groups) do
        if members then
            choices[#choices + 1] = {
                value = index,
                weight = math.ceil(1000 / #members),
            }
        end
    end

    local group_id = weighted_pick(builder, choices)

    if not group_id then
        return nil
    end

    choices = {}

    for _, cell in ipairs(groups[group_id]) do
        local remaining = 0

        for _, edge in ipairs(incident[cell]) do
            if not edge.style then
                remaining = remaining + 1
            end
        end

        choices[#choices + 1] = {
            value = cell,
            weight = remaining,
        }
    end

    return weighted_pick(builder, choices)
end

-- Draw a qualifying border from one cell. The second connect pass permits
-- an internal edge as well as a link between different groups.
local function choose_border(builder, cell, incident, owner, minimum_border, extra)
    local choices = {}

    for _, edge in ipairs(incident[cell]) do
        if not edge.style and edge.length >= minimum_border and
            (extra or owner[edge.first] ~= owner[edge.second]) then
            choices[#choices + 1] = {
                value = edge,
                weight = 10,
            }
        end
    end

    return weighted_pick(builder, choices)
end

-- Merge all cells of the smaller group into the selected group after a
-- border connects them. Source group choices then use the new group size.
local function merge(groups, owner, first, second)
    local target = owner[first]
    local source = owner[second]

    if target == source then
        return false
    end

    for _, cell in ipairs(groups[source]) do
        groups[target][#groups[target] + 1] = cell
        owner[cell] = target
    end

    groups[source] = false
    return true
end

-- Draw a source connection style: a door is rarer than an open border even
-- when this layout's per-floor door option was enabled.
local function choose_style(builder, doors)
    if doors and builder:one_in(3) then
        return "door"
    end

    return "open"
end

-- Run one source connection attempt. A selected cell can lack a qualifying
-- border; that attempt still consumes its draws and counts toward the cap.
local function connect_attempt(builder, groups, owner, incident,
    minimum_border, doors, extra)
    local cell = choose_group_cell(builder, groups, incident)

    if not cell then
        return false
    end

    local edge = choose_border(builder, cell, incident, owner,
        minimum_border, extra)

    if not edge then
        return false
    end

    edge.style = choose_style(builder, doors)

    local other = edge.first == cell and edge.second or edge.first

    return merge(groups, owner, cell, other)
end

-- First connect separate cell groups with the source's 500-attempt cap.
-- The optional second pass breaks extra walls to reduce tree-like corridors.
function graph.connect(builder, edges, cell_count, minimum_border, doors, extra)
    local groups, owner, incident = initial_groups(edges, cell_count)
    local components = cell_count

    for _ = 1, 500 do
        if components <= 1 then
            break
        end

        if connect_attempt(builder, groups, owner, incident,
            minimum_border, doors, false) then
            components = components - 1
        end
    end

    for _ = 1, extra do
        connect_attempt(builder, groups, owner, incident,
            minimum_border, doors, true)
    end

    return components
end

-- Fill the entire cell rectangle with floor before source wall segments are
-- restored. This keeps the vast interior of each cell traversable.
local function paint_cells(builder, cells)
    for _, cell in ipairs(cells) do
        for y = cell.y1, cell.y2 do
            for x = cell.x1, cell.x2 do
                builder:set(x, y, ".")
            end
        end
    end
end

-- Thin Dungeon walls occupy one side of each unconnected cell boundary.
-- Door midpoints are painted after all walls so crossings cannot erase one.
local function paint_thin(builder, edges)
    local doors = {}

    for _, edge in ipairs(edges) do
        if edge.style ~= "open" then
            if edge.orientation == "vertical" then
                for y = edge.y1, edge.y2 do
                    builder:set(edge.x1, y, "#")
                end

                if edge.style == "door" then
                    doors[#doors + 1] = {
                        x = edge.x1,
                        y = math.floor((edge.y1 + edge.y2) / 2),
                    }
                end
            else
                for x = edge.x1, edge.x2 do
                    builder:set(x, edge.y1, "#")
                end

                if edge.style == "door" then
                    doors[#doors + 1] = {
                        x = math.floor((edge.x1 + edge.x2) / 2),
                        y = edge.y1,
                    }
                end
            end
        end
    end

    for _, point in ipairs(doors) do
        builder:set(point.x, point.y, "+")
    end
end

-- Thick non-Dungeon walls occupy both touching cell sides. A door opens one
-- side and plain floor opens the other so the pair remains traversable.
local function paint_thick(builder, edges)
    local doors = {}

    for _, edge in ipairs(edges) do
        if edge.style ~= "open" then
            if edge.orientation == "vertical" then
                for y = edge.y1, edge.y2 do
                    builder:set(edge.x1, y, "#")
                    builder:set(edge.x2, y, "#")
                end

                if edge.style == "door" then
                    doors[#doors + 1] = {
                        x = edge.x1,
                        y = math.floor((edge.y1 + edge.y2) / 2),
                    }
                    doors[#doors + 1] = {
                        x = edge.x2,
                        y = math.floor((edge.y1 + edge.y2) / 2),
                        floor = true,
                    }
                end
            else
                for x = edge.x1, edge.x2 do
                    builder:set(x, edge.y1, "#")
                    builder:set(x, edge.y2, "#")
                end

                if edge.style == "door" then
                    doors[#doors + 1] = {
                        x = math.floor((edge.x1 + edge.x2) / 2),
                        y = edge.y1,
                    }
                    doors[#doors + 1] = {
                        x = math.floor((edge.x1 + edge.x2) / 2),
                        y = edge.y2,
                        floor = true,
                    }
                end
            end
        end
    end

    for _, point in ipairs(doors) do
        builder:set(point.x, point.y, point.floor and "." or "+")
    end
end

-- Paint a fully chosen cell graph with the branch's source wall thickness.
function graph.paint(builder, cells, edges, thin)
    paint_cells(builder, cells)

    if thin then
        paint_thin(builder, edges)
    else
        paint_thick(builder, edges)
    end
end

-- Tar's source maze crenellates the room-side strips beside closed borders.
-- Alternate rocks from a random end and leave a door's midpoint clear.
function graph.fortify(builder, edges)
    for _, edge in ipairs(edges) do
        if edge.style ~= "open" and edge.length >= 3 then
            local reverse = builder:roll(2) == 0
            local midpoint

            if edge.orientation == "vertical" then
                midpoint = math.floor((edge.y1 + edge.y2) / 2)
            else
                midpoint = math.floor((edge.x1 + edge.x2) / 2)
            end

            for index = 1, edge.length - 2 do
                if index % 2 == 1 then
                    local offset = reverse and edge.length - index - 1 or index

                    if edge.orientation == "vertical" then
                        local y = edge.y1 + offset

                        if edge.style ~= "door" or y ~= midpoint then
                            builder:set(edge.x1 - 1, y, "#")
                            builder:set(edge.x2 + 1, y, "#")
                        end
                    else
                        local x = edge.x1 + offset

                        if edge.style ~= "door" or x ~= midpoint then
                            builder:set(x, edge.y1 - 1, "#")
                            builder:set(x, edge.y2 + 1, "#")
                        end
                    end
                end
            end
        end
    end
end

-- Fill playable islands beyond the largest one with rock, or a source
-- feature such as deep water. The caller names passable terrain for its
-- source-specific zone pass; the default remains ordinary floor and doors.
function graph.keep_largest_region(builder, passable, fill_glyph)
    passable = passable or {
        ["."] = true,
        ["+"] = true,
    }
    local visited = {}
    local largest = {}
    local directions = {
        { x = 1, y = 0 },
        { x = -1, y = 0 },
        { x = 0, y = 1 },
        { x = 0, y = -1 },
    }

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local first_key = y * grid.width + x
            local glyph = builder:cell(x, y)

            if not visited[first_key] and passable[glyph] then
                local queue = { { x = x, y = y } }
                local region = {}
                local index = 1

                visited[first_key] = true

                while index <= #queue do
                    local point = queue[index]
                    index = index + 1
                    region[#region + 1] = point

                    for _, direction in ipairs(directions) do
                        local next_x = point.x + direction.x
                        local next_y = point.y + direction.y
                        local next_key = next_y * grid.width + next_x
                        local next_glyph = builder:cell(next_x, next_y)

                        if builder:inside({ x = next_x, y = next_y }) and
                            not visited[next_key] and
                            passable[next_glyph] then
                            visited[next_key] = true
                            queue[#queue + 1] = { x = next_x, y = next_y }
                        end
                    end
                end

                if #region > #largest then
                    largest = region
                end
            end
        end
    end

    local retained = {}

    for _, point in ipairs(largest) do
        retained[point.y * grid.width + point.x] = true
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local glyph = builder:cell(x, y)

            if passable[glyph] and
                not retained[y * grid.width + x] then
                builder:set(x, y, fill_glyph or "#")
            end
        end
    end
end

return graph
