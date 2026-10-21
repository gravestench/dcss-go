-- Theory of operation: some source Lair entrances substitute walls and
-- hazards around the keyed O stair. Reject a candidate unless that final
-- local geometry still gives the player a traversable path to an edge.
local glyphs = require("constants.vault_glyphs")

local handler = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
    { x = 1, y = 1 },
    { x = 1, y = -1 },
    { x = -1, y = 1 },
    { x = -1, y = -1 },
}

-- Source has_exit_from_glyph treats an edge opening as reachable only when
-- the path does not need to cross a wall, deep water, or lava.
local function passable(glyph)
    return glyph ~= nil and glyph ~= " " and
        not glyphs.wall[glyph] and glyph ~= "w" and glyph ~= "l"
end

-- Search from the substituted O cell, since an authored source coordinate
-- is no longer reliable after NSUBST and SHUFFLE have run.
local function has_exit(api)
    local cells = api.cells
    local queue = {}
    local seen = {}

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if glyph == "O" then
                queue[#queue + 1] = { x = x, y = y }
                seen[x .. ":" .. y] = true
            end
        end
    end

    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]
        local row = cells[point.y]

        cursor = cursor + 1

        if point.x == 1 or point.y == 1 or
            point.x == #row or point.y == #cells then
            return true
        end

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local next_row = cells[y]
            local glyph = next_row and next_row[x]
            local key = x .. ":" .. y

            if passable(glyph) and not seen[key] then
                seen[key] = true
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end

    return false
end

handler.has_exit = has_exit

return handler
