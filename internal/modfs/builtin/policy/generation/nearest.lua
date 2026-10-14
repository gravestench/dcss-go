local nearest = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

local function key(point)
    return point.x .. ":" .. point.y
end

local function cell(rows, x, y)
    if y < 0 or y >= #rows or x < 0 or x >= #rows[1] then
        return nil
    end

    return rows[y + 1]:sub(x + 1, x + 1)
end

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

return nearest
