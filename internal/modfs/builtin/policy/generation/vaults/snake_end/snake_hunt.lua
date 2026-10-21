-- Theory of operation: source substitutions can cut passages in either
-- wing of the Hunt. The source validator rejects a generated variant when
-- no surviving entrance stair can reach the rune. We inspect final DES
-- cells before they are projected onto the whole floor.
local glyphs = require("constants.vault_glyphs")

local handler = {}

local directions = {
    {
        x = 1,
        y = 0,
    },
    {
        x = -1,
        y = 0,
    },
    {
        x = 0,
        y = 1,
    },
    {
        x = 0,
        y = -1,
    },
    {
        x = 1,
        y = 1,
    },
    {
        x = -1,
        y = 1,
    },
    {
        x = 1,
        y = -1,
    },
    {
        x = -1,
        y = -1,
    },
}

-- Source glyphs_connected uses ordinary feature traversability and all
-- eight neighbors. Wall glyphs, deep water, lava, and blank padding cannot
-- join an entrance to the rune; doors and floor placeholders can.
local function passable(glyph)
    return glyph ~= nil and glyph ~= " " and
        not glyphs.wall[glyph] and glyph ~= "w" and glyph ~= "l"
end

-- Begin at every surviving `{` so the optional source stair substitution
-- does not make the result depend on which candidate appears first.
local function entrances(cells)
    local points = {}

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if glyph == "{" then
                points[#points + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return points
end

-- Walk only authored cells. Reaching O proves a route inside the selected
-- map, independent of corridors that later connect it to the base floor.
local function connected_rune(api)
    local cells = api.cells
    local queue = entrances(cells)
    local seen = {}
    local cursor = 1

    for _, point in ipairs(queue) do
        seen[point.x .. ":" .. point.y] = true
    end

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        if cells[point.y][point.x] == "O" then
            return true
        end

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local row = cells[y]
            local glyph = row and row[x]
            local key = x .. ":" .. y

            if passable(glyph) and not seen[key] then
                seen[key] = true
                queue[#queue + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return false
end

handler.connected_rune = connected_rune

return handler
