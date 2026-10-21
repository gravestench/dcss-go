-- DCSS COLOURS uses IRGB order; the terminal owns ANSI conversion.
-- Example: a view writes fg = colors.light_red, while a content color name
-- uses colors.source["LIGHTRED"]. Keeping both paths here avoids mismatches.
local elements = require("constants.element_colours")

local colors = {
    black = 0,
    blue = 1,
    green = 2,
    cyan = 3,
    red = 4,
    magenta = 5,
    brown = 6,
    light_grey = 7,
    dark_grey = 8,
    light_blue = 9,
    light_green = 10,
    light_cyan = 11,
    light_red = 12,
    light_magenta = 13,
    yellow = 14,
    white = 15,
}

colors.random_effect_id = elements.RANDOM

-- colour.cc::_etc_random uses ui_random(15) and adds one. Keep the exact
-- nonblack IRGB ordering here so presentation never consumes game RNG.
colors.nonblack_irgb = {
    colors.blue,
    colors.green,
    colors.cyan,
    colors.red,
    colors.magenta,
    colors.brown,
    colors.light_grey,
    colors.dark_grey,
    colors.light_blue,
    colors.light_green,
    colors.light_cyan,
    colors.light_red,
    colors.light_magenta,
    colors.yellow,
    colors.white,
}

colors.source = {
    BLACK = colors.black,
    BLUE = colors.blue,
    GREEN = colors.green,
    CYAN = colors.cyan,
    RED = colors.red,
    MAGENTA = colors.magenta,
    BROWN = colors.brown,
    LIGHTGREY = colors.light_grey,
    DARKGREY = colors.dark_grey,
    LIGHTBLUE = colors.light_blue,
    LIGHTGREEN = colors.light_green,
    LIGHTCYAN = colors.light_cyan,
    LIGHTRED = colors.light_red,
    LIGHTMAGENTA = colors.light_magenta,
    YELLOW = colors.yellow,
    WHITE = colors.white,
    ETC_HOLY = colors.yellow,
    ETC_MIST = colors.light_grey,
    ETC_MUTAGENIC = colors.magenta,
    ETC_MAGIC = colors.light_magenta,
    ETC_VORTEX = colors.light_cyan,
    ETC_EARTH = colors.brown,
    ETC_ELECTRICITY = colors.light_blue,
    ETC_DARK = colors.dark_grey,
    ETC_INCARNADINE = colors.red,
    ETC_AIR = colors.light_cyan,
    ETC_SMOKE = colors.red,
    ETC_FIRE = colors.light_red,
}

colors.source[colors.random_effect_id] = colors.magenta

return colors
