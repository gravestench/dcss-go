-- This crypt has a fixed broken-pillar name and an authored matching tile.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Preserve the local statue rename as a typed source feature effect.
local function feature_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.BROKEN_PILLAR,
    })
end

handler.feature_name = feature_name

return handler
