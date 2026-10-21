-- Source Zot hoards and glass rooms call these same setup routines from
-- several distinct MAPs. Each caller keeps its own geometry in DES.
local directives = require("constants.vault_directives")

local shared = {}

-- Hoard maps use one guardian roster. Their no_item_gen tag and Zot depth
-- are static DES metadata because catalog selection runs before this hook.
local function dragon_hoard_setup(api)
    api:emit(directives.KMONS,
        "D = acid dragon / fire dragon w:25 / ice dragon w:25 / " ..
        "storm dragon w:20 / shadow dragon w:20 / golden dragon / " ..
        "iron dragon w:5 / quicksilver dragon w:5 / bone dragon w:5 / " ..
        "lindwurm w:2 / rime drake w:2 / death drake w:2 / " ..
        "swamp dragon w:5")
    api:emit(directives.KMONS,
        "d = base draconian / nonbase draconian")
    api:emit(directives.KMONS, "Y = patrolling golden dragon")
    api:emit(directives.KITEM, "Y = |")
end

-- The source shuffles colour glyphs before binding transparent walls.
-- Keeping the ordered tile and colour assignments together means adding
-- another glass map does not duplicate seven subtly different palettes.
local function coloured_glass(api)
    api:emit(directives.SHUFFLE, "roygbiv")
    api:emit(directives.KFEAT, "roygbiv = m")

    local tiles = {
        "r = dngn_transparent_wall_red",
        "o = dngn_transparent_wall_brown",
        "y = dngn_transparent_wall_yellow",
        "g = dngn_transparent_wall_green",
        "b = dngn_transparent_wall_blue",
        "i = dngn_transparent_wall",
        "v = dngn_transparent_wall_magenta",
    }

    for _, expression in ipairs(tiles) do
        api:emit(directives.TILE, expression)
    end

    local colours = {
        "r = red",
        "o = brown",
        "y = yellow",
        "g = green",
        "b = blue",
        "i = cyan",
        "v = magenta",
    }

    for _, expression in ipairs(colours) do
        api:emit(directives.COLOUR, expression)
    end
end

shared.dragon_hoard_setup = dragon_hoard_setup
shared.coloured_glass = coloured_glass

return shared
