-- This source validator rejects water substitutions that seal the keyed
-- Shoals stair inside the room maze. It runs after substitutions, before
-- this candidate changes the parent Lair floor.
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

-- The source test asks whether the stair can reach an exit through cells
-- a normal character can enter. Deep water and walls block that route.
local function passable(glyph)
    return glyph ~= nil and glyph ~= " " and
        not glyphs.wall[glyph] and glyph ~= "w" and glyph ~= "l"
end

-- An authored edge cell, including transparent @, opens onto the floor
-- around the vault. Search from the surviving O rather than its source
-- coordinates because NSUBST can change nearby water and monster slots.
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
