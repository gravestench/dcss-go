-- random_colour() draws IRGB values 1..15, then random_monster_colour()
-- rerolls DARKGREY. The source one-in-ten ETC_RANDOM choice is separate.
local elements = require("constants.element_colours")

local colours = {
    RANDOM_EFFECT = elements.RANDOM,
    DARK_GREY = "DARKGREY",
    SOURCE = {
        "BLUE",
        "GREEN",
        "CYAN",
        "RED",
        "MAGENTA",
        "BROWN",
        "LIGHTGREY",
        "DARKGREY",
        "LIGHTBLUE",
        "LIGHTGREEN",
        "LIGHTCYAN",
        "LIGHTRED",
        "LIGHTMAGENTA",
        "YELLOW",
        "WHITE",
    },
}

colours.VALID = {
    [colours.RANDOM_EFFECT] = true,
}

for _, id in ipairs(colours.SOURCE) do
    if id ~= colours.DARK_GREY then
        colours.VALID[id] = true
    end
end

return colours
