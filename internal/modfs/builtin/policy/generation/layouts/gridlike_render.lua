-- Theory of operation: source Gridlike paints all room interiors, adds
-- selected walls and doors between neighboring rooms, then draws L-shaped
-- corridors from each corridor cell's center to its shared borders.
-- Corners may be clipped before the corridors open their connections.
local subdivision = require("policy.generation.layouts.subdivision")

local render = {}

-- Paint one inclusive source rectangle. All callers pass cell-local bounds
-- within the full level grid, so no global geometry state is required.
local function fill(builder, x1, y1, x2, y2, glyph)
    for y = math.min(y1, y2), math.max(y1, y2) do
        for x = math.min(x1, x2), math.max(x1, x2) do
            builder:set(x, y, glyph)
        end
    end
end

-- Each shared edge is incident to exactly two cells. An ordered list per
-- cell lets room and corridor passes retain the source partition order.
local function incidents(cells, edges)
    local lists = {}

    for index = 1, #cells do
        lists[index] = {}
    end

    for _, edge in ipairs(edges) do
        lists[edge.first][#lists[edge.first] + 1] = edge
        lists[edge.second][#lists[edge.second] + 1] = edge
    end

    return lists
end

-- Find the other partition cell across a shared border.
local function opposite(edge, index)
    return edge.first == index and edge.second or edge.first
end

-- Return the strip on this cell's side of a shared edge. Adjacent source
-- rectangles own distinct border coordinates on either side of the seam.
local function side(edge, cell)
    if edge.orientation == "vertical" then
        local x = cell.x2 == edge.x1 and edge.x1 or edge.x2

        return x, edge.y1
    end

    local y = cell.y2 == edge.y1 and edge.y1 or edge.y2

    return edge.x1, y
end

-- Fill every room first so later walls and corridors cannot be erased by
-- an adjacent room's base floor pass.
local function room_floors(builder, cells)
    for _, cell in ipairs(cells) do
        if cell.tile == "room" then
            fill(builder, cell.x1, cell.y1, cell.x2, cell.y2, ".")
        end
    end
end

-- Source render_walls chooses a door-owning room and suppresses that choice
-- in neighboring rooms. This prevents two competing doors on one seam.
local function door_owners(builder, cells, lists, choices)
    if not choices.doors then
        return
    end

    for index, cell in ipairs(cells) do
        if cell.tile == "room" and cell.has_doors == nil then
            cell.has_doors = builder:one_in(2)

            if cell.has_doors then
                for _, edge in ipairs(lists[index]) do
                    local neighbor = cells[opposite(edge, index)]

                    if neighbor.tile == "room" then
                        neighbor.has_doors = false
                    end
                end
            end
        end
    end
end

-- A room-owned seam becomes a wall on that room's side with one door at
-- an interior border position; the other room retains open floor.
local function room_walls(builder, cells, lists)
    for index, cell in ipairs(cells) do
        if cell.tile == "room" and cell.has_doors then
            for _, edge in ipairs(lists[index]) do
                local neighbor = cells[opposite(edge, index)]

                if neighbor.tile == "room" and edge.length >= 3 then
                    local x, y = side(edge, cell)
                    local offset = subdivision.range(builder, 1,
                        edge.length - 2)

                    if edge.orientation == "vertical" then
                        fill(builder, x, edge.y1, x, edge.y2, "#")
                        builder:set(x, y + offset, "+")
                    else
                        fill(builder, edge.x1, y, edge.x2, y, "#")
                        builder:set(x + offset, y, "+")
                    end
                end
            end
        end
    end
end

-- Never overwrite an authored door while clipping an open room corner.
local function clip_floor(builder, x, y)
    if builder:cell(x, y) == "." then
        builder:set(x, y, "#")
    end
end

-- Source corner rendering protects border openings by cutting only the
-- unconnected outer tip of a room. A corridor drawn later can reopen it.
local function clipped_corners(builder, cells, choices)
    if not choices.corners then
        return
    end

    for _, cell in ipairs(cells) do
        if cell.tile == "room" then
            local width = cell.x2 - cell.x1 + 1
            local height = cell.y2 - cell.y1 + 1
            local cut = math.floor(math.min(width, height) / 4)

            for offset_y = 0, cut - 1 do
                for offset_x = 0, cut - offset_y - 1 do
                    clip_floor(builder,
                        cell.x1 + offset_x, cell.y1 + offset_y)
                    clip_floor(builder,
                        cell.x2 - offset_x, cell.y1 + offset_y)
                    clip_floor(builder,
                        cell.x1 + offset_x, cell.y2 - offset_y)
                    clip_floor(builder,
                        cell.x2 - offset_x, cell.y2 - offset_y)
                end
            end
        end
    end
end

-- Choose one shared passage width and border offset. Mid-door branches
-- center the passage; other branches draw a random interior position.
local function edge_passage(builder, edge, choices)
    if edge.width then
        return edge.width, edge.offset
    end

    local maximum = math.min(choices.maxcorridor, edge.length - 2)

    edge.width = choices.big_corridors and maximum or
        subdivision.range(builder, 1, maximum)

    local span = edge.length - edge.width - 1

    if choices.mid_doors then
        edge.offset = math.max(1, math.floor(span / 2))
    else
        edge.offset = subdivision.range(builder, 1, span)
    end

    return edge.width, edge.offset
end

-- A corridor may use a regular cell center or a per-cell random origin.
-- The same origin joins all of its incident border passages.
local function corridor_center(builder, cell, choices)
    if choices.regular_grid then
        return math.floor((cell.x1 + cell.x2) / 2),
            math.floor((cell.y1 + cell.y2) / 2)
    end

    return subdivision.range(builder, cell.x1, cell.x2),
        subdivision.range(builder, cell.y1, cell.y2)
end

-- Connect one border stripe to the cell center with the source right-angle
-- bend. Crossing into a room opens its own boundary cell as floor or door.
local function carve_passage(builder, edge, cell, neighbor, center_x,
    center_y, offset, choices)
    local side_x, side_y = side(edge, cell)

    if edge.orientation == "vertical" then
        local y = side_y + offset

        fill(builder, side_x, y, side_x, center_y, ".")
        fill(builder, side_x, center_y, center_x, center_y, ".")

        if neighbor.tile == "room" then
            local neighbor_x = side(edge, neighbor)

            builder:set(neighbor_x, y,
                choices.corridor_doors and "+" or ".")
        end
    else
        local x = side_x + offset

        fill(builder, x, side_y, center_x, side_y, ".")
        fill(builder, center_x, side_y, center_x, center_y, ".")

        if neighbor.tile == "room" then
            local _, neighbor_y = side(edge, neighbor)

            builder:set(x, neighbor_y,
                choices.corridor_doors and "+" or ".")
        end
    end
end

-- Render corridor cells after rooms, so every L path can cut through a
-- clipped room corner or a wall between neighboring room groups.
local function corridors(builder, cells, lists, choices)
    for index, cell in ipairs(cells) do
        if cell.tile == "corridor" then
            local center_x, center_y = corridor_center(builder, cell, choices)

            builder:set(center_x, center_y, ".")

            for _, edge in ipairs(lists[index]) do
                local neighbor = cells[opposite(edge, index)]

                if edge.length >= 3 and
                    (neighbor.tile == "room" or
                        neighbor.tile == "corridor") then
                    local width, offset = edge_passage(builder, edge, choices)

                    for stripe = 0, width - 1 do
                        carve_passage(builder, edge, cell, neighbor,
                            center_x, center_y, offset + stripe, choices)
                    end
                end
            end
        end
    end
end

-- The renderer owns the order in which room walls, clipped corners, and
-- corridor cuts affect the shared grid; materials are a later room pass.
function render.paint(builder, cells, edges, choices)
    local lists = incidents(cells, edges)

    room_floors(builder, cells)
    door_owners(builder, cells, lists, choices)
    room_walls(builder, cells, lists)
    clipped_corners(builder, cells, choices)
    corridors(builder, cells, lists, choices)
end

return render
