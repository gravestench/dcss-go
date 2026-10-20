-- This rare one-altar Temple paints its walls, floor, and scenery with
-- one shared source colour. A single draw keeps the theme coherent.
local directives = require("constants.vault_directives")

local handler = {}

local colours = {
    "blue", "cyan", "green", "yellow", "red", "magenta", "white",
    "lightblue", "lightcyan", "lightgreen", "lightred", "lightmagenta",
}

-- Emit the selected colour where the source {{ }} block appeared. The
-- choice remains local to this vault, independent of other Temple maps.
local function configure(api)
    local colour = colours[api:roll(#colours) + 1]

    api:emit(directives.LFLOORCOL, colour)
    api:emit(directives.LFLOORTILE, "floor_pebble_" .. colour)
    api:emit(directives.COLOUR, "Gb = " .. colour)
end

handler.configure = configure

return handler
