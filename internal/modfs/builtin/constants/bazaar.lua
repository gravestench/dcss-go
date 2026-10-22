-- Bazaar's setup hook saves one palette choice for later script sites in
-- the same DES map. Shared names prevent its colour-dependent maps from
-- silently drifting when a palette or hook key changes.
local bazaar = {
    COLOUR_SETTING = "bazaar_colour",
    BLUE = "blue",
    RED = "red",
    LIGHTBLUE = "lightblue",
    MAGENTA = "magenta",
    GREEN = "green",
    TIMED_MARKER = "lua:timed_marker",
    ONE_WAY_MARKER = "lua:one_way_stair",
}

return bazaar
