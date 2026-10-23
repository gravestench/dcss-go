-- wizlab_lehudib keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local map = {}

-- The source mixes useful scrolls and potions in one reward slot.
function map.site_1(api)
    api:emit(directives.ITEM,
        loot.SCROLLS .. " / " .. loot.POTIONS)
end

-- One jewellery or high-quality auxiliary armour draw follows the
-- mutation potion. Source keeps randart jewellery at weight sixty.
function map.site_2(api)
    api:emit(directives.ITEM,
        "any randart jewellery w:60 / " .. loot.GOOD_AUX_ARMOUR)
end

-- Random summons use this alien roster. The two named transporter pairs
-- are static MARKER declarations immediately after this source block.
function map.site_3(api)
    shared.random_monsters(api,
        "eye of devastation / stone giant / tentacled starspawn / " ..
        "glowing orange brain / great orb of eyes / neqoxec w:5 / " ..
        "golden eye w:5 / very ugly thing w:5 / " ..
        "starcursed mass w:5 / cacodemon w:1 / " ..
        "quicksilver dragon w:1 / war gargoyle w:1 / " ..
        "crystal guardian w:1 / wretched star w:1")
end

-- Apply the shared whole-floor setup after the map-local terrain and
-- transporter declarations, matching the source's final hook position.
function map.site_4(api)
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Lehudib's Moon Base")
end

return map
