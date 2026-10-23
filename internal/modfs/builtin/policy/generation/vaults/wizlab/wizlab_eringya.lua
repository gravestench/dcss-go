-- wizlab_eringya keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local map = {}

-- Add the source useful-potion draw ahead of the spectral weapon slot.
function map.site_1(api)
    api:emit(directives.ITEM, loot.POTIONS)
end

-- Only one in four gardens recolours its trees for autumn. Keeping both
-- appearance directives inside this one choice avoids a half-changed map.
function map.site_2(api)
    if not api:one_in(4) then
        return
    end

    api:emit(directives.COLOUR,
        "t = lightred / red w:3 / green w:3 / lightgreen w:1")
    api:emit(directives.TILE,
        "t = dngn_tree_lightred / dngn_tree_red w:4 / " ..
        "dngn_tree_yellow w:4")
end

-- The garden's random-monster roster excludes its keyed oklob plants
-- and matches the source's lower odds for its most dangerous archers.
function map.site_4(api)
    shared.random_monsters(api,
        "deep elf archer / faun / centaur warrior / yaktaur / " ..
        "satyr / naga sharpshooter / shambling mangrove / " ..
        "thorn hunter w:5 / eleionoma w:5 / " ..
        "deep elf master archer w:2")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Eringya's Formal Garden")
end

return map
