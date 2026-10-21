-- Cocytus end-map setup from crawl-ref/source/dat/des/branches/coc.des.
-- Each controller calls these methods where the source executes its setup.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local fill = require("constants.vault_border_fill")
local serpent = require("policy.generation.hell.serpent")

local handler = {}

-- The source chooses one persistent Hell branch for the Serpent. The shared
-- generation API owns that choice and checks its unique history before
-- assigning the D glyph; a local draw would allow multiple Hell Serpents.
function handler.serpent_of_hell(api)
    serpent.setup(api, {
        glyph = "D",
        branch_id = branches.BRANCH_COCYTUS,
        monster_id = monsters.MONS_SERPENT_OF_HELL,
    })
end

-- PLACE: Coc:$ and TAGS: no_rotate are static DES metadata because selection
-- and orientation consume them before operation hooks run. The remaining
-- source coc_setup declarations are emitted here in their original order.
function handler.coc_setup(api)
    api:emit(directives.KITEM, "$ = $ no_pickup")
    api:emit(directives.KMASK, "O = no_item_gen")
    api:emit(directives.KITEM, "O = icy rune of Zot")
    api:emit(directives.LROCKCOL, "lightcyan")
    api:emit(directives.LFLOORCOL, "white")
    api:emit(directives.LFLOORTILE, "floor_ice")
    api:emit(directives.COLOUR, "c = lightblue")

    -- These names apply to this selected map's terrain, not the global
    -- terrain catalog. Rock wall and floor have no vault-feature aliases.
    api:record(effects.FEATURE_NAME, {
        feature = "rock_wall",
        name = "ice-covered rock wall",
    })

    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = "ice-covered stone wall",
    })

    api:record(effects.FEATURE_NAME, {
        feature = "floor",
        name = "Frost-covered floor",
    })
end

-- Grunt's two source calls both request an open-sea surround. Keep both hook
-- sites so operation order remains inspectable even though the style agrees.
function handler.open_sea_border(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
end

return handler
