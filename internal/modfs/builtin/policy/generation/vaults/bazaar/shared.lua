-- Every Bazaar layout calls this source setup at its original DES script
-- site. It creates the common arrival arch and exit, then selects one
-- tileset for colour-dependent substitutions in later named hooks.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local bazaar = require("constants.bazaar")
local fill = require("constants.vault_border_fill")

local shared = {}

local tilesets = {
    {
        colour = bazaar.BLUE,
        floor = "floor_grass",
        rock = "wall_brick_gray",
        halo = "halo_grass",
    },
    {
        colour = bazaar.RED,
        floor = "floor_vault",
        rock = "wall_pebble_red",
        halo = "halo_vault",
    },
    {
        colour = bazaar.LIGHTBLUE,
        floor = "floor_grass",
        rock = "wall_pebble_lightblue",
        halo = "halo_grass2",
    },
    {
        colour = bazaar.MAGENTA,
        floor = "floor_dirt",
        rock = "wall_stone_gray",
        halo = "halo_dirt",
    },
    {
        colour = bazaar.GREEN,
        floor = "floor_grass",
        rock = "wall_stone_gray",
        halo = "halo_grass",
    },
}

-- Source Bazaar setup prevents ordinary monsters, converts the two stair
-- glyphs, and stores the selected palette for later colour-sensitive hooks.
local function setup(api, randomise_tileset, shop_halo)
    api:emit(directives.KFEAT, "< = stone_arch")
    api:emit(directives.KFEAT, "> = exit_bazaar")

    if not randomise_tileset then
        return
    end

    local tileset = tilesets[api:roll(#tilesets) + 1]

    api:remember(bazaar.COLOUR_SETTING, tileset.colour)
    api:emit(directives.COLOUR, ". = " .. tileset.colour)
    api:emit(directives.FTILE, ". = " .. tileset.floor)
    api:emit(directives.RTILE, "x = " .. tileset.rock)

    if shop_halo then
        api:record(effects.GENERATION_RULE, {
            rule = "bazaar_shop_halo",
            tile = tileset.halo,
        })
    end
end

-- Normal Bazaar maps use a palette and halos around their shop entrances.
function shared.setup(api)
    setup(api, true, true)
end

-- The hand-coloured source maps keep their own terrain and skip halos.
function shared.setup_plain(api)
    setup(api, false, false)
end

-- Preserve the generated cavern's surrounding lava as a typed level effect.
function shared.border_lava(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_LAVA,
    })
end

-- The lighthouse layout uses open sea beyond its authored map edge.
function shared.border_sea(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

return shared
