-- The garden ending uses planted rune and decoy islands. Its controller
-- owns selection; the individual island shapes stay in the DES corpus.
local finale = require("policy.generation.vaults.shoals_end.finale")
local tags = require("constants.vault_tags")

local handler = {}
local theme = {
    rune = tags.SHOAL_RUNE_GRUNT_GARDEN,
    mimic = tags.SHOAL_MIMIC_GRUNT_GARDEN,
    hut = tags.SHOAL_HUT_GRUNT_GARDEN,
    minimum = 5,
    maximum = 6,
}

-- Place the matching garden children after the end draw.
function handler.assemble(api)
    finale.assemble(api, theme)
end

-- Keep the garden rune's helper identity in saved history.
function handler.require_rune(result)
    return finale.require_rune(result, theme)
end

return handler
