-- Theory of operation: two source arena maps ask for a random whole-map
-- palette. The old DES global Lua chose rock/floor colours and tiles in
-- that order. Arena maps encompass their levels, so emitted cell style
-- directives carry those choices into the same typed vault records used
-- by the rest of the port. The ASCII client can use colours now; a tiles
-- client can use the tile choices from the saved records later.
-- Source: crawl-ref/source/dat/des/builder/arena.des.
local directives = require("constants.vault_directives")

local arena = {}

local colours = {
    "blue",
    "green",
    "cyan",
    "red",
    "magenta",
    "brown",
    "lightgrey",
    "darkgrey",
    "lightblue",
    "lightgreen",
    "lightcyan",
    "lightred",
    "lightmagenta",
    "yellow",
    "white",
}

local walls = {
    "wall_normal",
    "wall_hall",
    "wall_lair",
    "wall_orc",
    "wall_snake",
    "wall_swamp",
    "wall_tomb",
    "wall_vault",
    "wall_zot_blue",
    "wall_zot_cyan",
    "wall_zot_lightgray",
    "wall_zot_green",
    "wall_zot_magenta",
    "wall_zot_red",
    "wall_zot_yellow",
    "wall_flesh",
    "wall_vines",
    "wall_pebble_red",
    "wall_yellow_rock",
    "wall_brick_gray",
    "wall_stone_gray",
    "wall_undead",
}

local floors = {
    "floor_normal",
    "floor_hall",
    "floor_ice",
    "floor_lair",
    "floor_orc",
    "floor_mosaic",
    "floor_swamp",
    "floor_tomb",
    "floor_vault",
    "floor_vines",
    "floor_rough_red",
    "floor_sand",
    "floor_grass",
    "floor_nerves",
    "floor_dirt",
    "floor_moss",
}

-- Draw each authored list once before emitting directives. Keeping the
-- draws in source order makes replacing this Lua file predictable for
-- modders and preserves the arena script's four independent choices.
function arena.randomise_colours(api)
    local rock_colour = api:random_from(colours)
    local floor_colour = api:random_from(colours)
    local wall_tile = api:random_from(walls)
    local floor_tile = api:random_from(floors)

    api:emit(directives.COLOUR, "X = " .. rock_colour)
    api:emit(directives.COLOUR, ". = " .. floor_colour)
    api:emit(directives.RTILE, "X = " .. wall_tile)
    api:emit(directives.FTILE, ". = " .. floor_tile)
end

return arena
