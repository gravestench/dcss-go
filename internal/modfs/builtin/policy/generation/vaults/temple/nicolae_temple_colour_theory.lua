-- Colour theory assigns one coordinated palette to its three pebble
-- regions. The source lists five palettes and chooses exactly one.
local directives = require("constants.vault_directives")

local handler = {}

local palettes = {
    { "lightblue", "lightred", "lightmagenta" },
    { "lightgreen", "lightred", "yellow" },
    { "lightblue", "lightgreen", "lightcyan" },
    { "lightblue", "yellow", "lightgreen" },
    { "lightred", "yellow", "brown" },
}

-- Use one draw for all three regions. Their floor tiles and feature
-- colours must refer to the same palette rather than diverging per cell.
local function configure(api)
    local palette = palettes[api:roll(#palettes) + 1]

    api:emit(directives.FTILE, "p' = floor_pebble_" .. palette[1])
    api:emit(directives.FTILE, "q` = floor_pebble_" .. palette[2])
    api:emit(directives.FTILE, "r{ = floor_pebble_" .. palette[3])
    api:emit(directives.COLOUR, "Pp = " .. palette[1])
    api:emit(directives.COLOUR, "Qq = " .. palette[2])
    api:emit(directives.COLOUR, "Rr = " .. palette[3])
end

handler.configure = configure

return handler
