-- Source has_exit_from_glyph validates a resolved DES room before the
-- vault is committed. Lair entrances and Zot's Orb hall use the same
-- passability rule but begin at different authored glyphs.
local glyphs = require("constants.vault_glyphs")

local paths = {}

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

-- A normal character cannot use a wall, deep water, or lava to prove a
-- map's intended branch exit is reachable. Source decorative glyphs and
-- shallow water remain traversable candidates.
local function passable(glyph)
    return glyph ~= nil and glyph ~= " " and
        not glyphs.wall[glyph] and glyph ~= "w" and glyph ~= "l"
end

-- Flood from every resolved copy of the named source glyph. The edge of
-- the local MAP is where the surrounding level's connector can meet it.
function paths.has_exit_from_glyph(cells, source_glyph)
    local queue = {}
    local seen = {}

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if glyph == source_glyph then
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

return paths
