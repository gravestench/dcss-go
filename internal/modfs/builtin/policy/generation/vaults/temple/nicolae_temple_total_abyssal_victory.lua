-- This rare Lugonu map sometimes adds bloody marks and independently
-- chooses source floor and wall palettes for its Abyssal scenery.
local directives = require("constants.vault_directives")

local handler = {}

local floor_colours = {
    "blue", "green", "red", "magenta", "brown", "lightgray",
    "lightblue", "lightgreen", "lightcyan", "lightred",
    "lightmagenta", "white",
}

local wall_colours = {
    "blue", "green", "red", "magenta", "brown", "lightblue",
    "lightgreen", "lightred", "lightmagenta", "yellow", "white",
}

-- Keep the one-in-five bloody floor substitution and its KPROP together;
-- the four clean outcomes emit neither instruction.
local function choose_blood(api)
    if api:roll(5) == 0 then
        api:emit(directives.SUBST, ". = '...")
        api:emit(directives.KPROP, "' = bloody")
    end
end

-- Draw walls and floor separately, as source Lua does, then emit the four
-- matching visual directives after the static Abyss exit tile.
local function choose_colours(api)
    local floor = floor_colours[api:roll(#floor_colours) + 1]
    local walls = wall_colours[api:roll(#wall_colours) + 1]

    api:emit(directives.COLOUR, "x = magenta w:2 / " .. walls)
    api:emit(directives.TILE, "x = wall_abyss")
    api:emit(directives.COLOUR, ". = magenta w:2 / " .. floor)
    api:emit(directives.FTILE,
        "_xpt{. = floor_nerves_magenta w:2 / floor_nerves_" .. floor)
end

handler.choose_blood = choose_blood
handler.choose_colours = choose_colours

return handler
