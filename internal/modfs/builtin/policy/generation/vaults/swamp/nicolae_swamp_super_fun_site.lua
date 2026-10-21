-- Theory of operation: the source dead-tree tile still uses mangrove
-- terrain, but the player should see a dead-mangrove feature name. Keep
-- that authored presentation as a typed record tied to this map.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Rename only this vault's mangroves; global terrain names stay shared.
local function rename_feature(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.MANGROVE,
        name = names.DEAD_MANGROVE,
    })
end

handler.rename_feature = rename_feature

return handler
