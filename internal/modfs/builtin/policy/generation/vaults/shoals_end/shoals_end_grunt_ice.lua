-- The ice ending uses iceberg helpers; the shared assembly policy retains
-- the source guardian and false-rune probabilities for this theme.
local finale = require("policy.generation.vaults.shoals_end.finale")
local tags = require("constants.vault_tags")

local handler = {}
local theme = {
    rune = tags.SHOAL_RUNE_GRUNT_ICE,
    mimic = tags.SHOAL_MIMIC_GRUNT_ICE,
    hut = tags.SHOAL_HUT_GRUNT_ICE,
    minimum = 5,
    maximum = 6,
}

-- Compose one real iceberg and the source-count surrounding islands.
function handler.assemble(api)
    finale.assemble(api, theme)
end

-- Reject a rune record from a different Shoals theme on restore.
function handler.require_rune(result)
    return finale.require_rune(result, theme)
end

return handler
