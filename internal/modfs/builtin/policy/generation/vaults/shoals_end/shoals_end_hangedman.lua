-- Hangedman's Shoals ending uses alternate rune and decoy islands.
-- Its smaller decoy range is a source rule, not a property of the maps.
local finale = require("policy.generation.vaults.shoals_end.finale")
local tags = require("constants.vault_tags")

local handler = {}
local theme = {
    rune = tags.SHOAL_RUNE_HANGEDMAN,
    mimic = tags.SHOAL_MIMIC_HANGEDMAN,
    hut = tags.SHOAL_HUT_HANGEDMAN,
    minimum = 5,
    maximum = 6,
}

-- Place this theme's children after the controller is selected.
function handler.assemble(api)
    finale.assemble(api, theme)
end

-- Check that the alternate rune child owns the sole real rune.
function handler.require_rune(result)
    return finale.require_rune(result, theme)
end

return handler
