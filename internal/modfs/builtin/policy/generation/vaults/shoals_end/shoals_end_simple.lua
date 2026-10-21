-- The simple Shoals ending assembles one real hut among six or seven decoys.
-- Source scripts placed these maps after controller selection; this module
-- keeps the decision in Lua while the authored huts remain DES maps.
local finale = require("policy.generation.vaults.shoals_end.finale")
local tags = require("constants.vault_tags")

local handler = {}
local theme = {
    rune = tags.SHOAL_RUNE_SIMPLE,
    mimic = tags.SHOAL_MIMIC_SIMPLE,
    hut = tags.SHOAL_HUT_SIMPLE,
    minimum = 6,
    maximum = 7,
}

-- Place the islands after the mapless controller wins the end draw.
function handler.assemble(api)
    finale.assemble(api, theme)
end

-- Validate both the live composition and its saved source history.
function handler.require_rune(result)
    return finale.require_rune(result, theme)
end

return handler
