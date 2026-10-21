-- Theory of operation: the tomb's clear rock wall is still ordinary terrain,
-- but its authored sarcophagus label must survive placement and save/restore.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Record the display name without changing the wall's gameplay feature.
local function sarcophagus_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.CLEAR_ROCK_WALL,
        name = names.SARCOPHAGUS,
    })
end

handler.sarcophagus_name = sarcophagus_name

return handler
