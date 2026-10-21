-- Example: A blocked start uses breadth-first search to find the nearest open floor.
local nearest = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- Track BFS positions by coordinate without depending on table identity.
local function key(point)
    return point.x .. ":" .. point.y
end

-- Treat out-of-bounds neighbors as blocked before indexing row strings.
local function cell(rows, x, y)
    if y < 0 or y >= #rows or x < 0 or x >= #rows[1] then
        return nil
    end

    return rows[y + 1]:sub(x + 1, x + 1)
end

-- Breadth-first search accepts the first reachable floor outside the excluded cells.
function nearest.open_floor(rows, start, exclude, depth)
    local queue = { start }
    local seen = {
        [key(start)] = true,
    }
    local first = 1

    while first <= #queue do
        local current = queue[first]
        first = first + 1

        if cell(rows, current.x, current.y) == "." and
            (not exclude or current.x ~= exclude.x or current.y ~= exclude.y) then
            return {
                x = current.x,
                y = current.y,
            }
        end

        for _, direction in ipairs(directions) do
            local next_cell = {
                x = current.x + direction.x,
                y = current.y + direction.y,
            }
            local glyph = cell(rows, next_cell.x, next_cell.y)
            local id = key(next_cell)

            if glyph and not seen[id] and glyph ~= "#" then
                seen[id] = true
                queue[#queue + 1] = next_cell
            end
        end
    end

    error(string.format("Dungeon:%d has no reachable open floor", depth))
end

-- Feature overlays run after glyph carving. If they turn a proposed entry
-- into a wall, find the closest final floor without treating raw glyphs as
-- authoritative terrain. Equal distances use row then column order.
function nearest.open_feature(cells, start, feature)
    local best
    local best_distance

    for row_index, row in ipairs(cells) do
        for column_index, actual in ipairs(row) do
            if actual == feature then
                local x = column_index - 1
                local y = row_index - 1
                local distance = math.abs(x - start.x) +
                    math.abs(y - start.y)

                if best_distance == nil or distance < best_distance then
                    best = {
                        x = x,
                        y = y,
                    }
                    best_distance = distance
                end
            end
        end
    end

    if not best then
        error("generated level has no open floor after feature placement")
    end

    return best
end

return nearest
