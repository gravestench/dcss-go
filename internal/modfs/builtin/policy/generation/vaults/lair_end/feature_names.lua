-- Theory of operation: source Jungle Book names its tree features "dead
-- tree" within this vault. A typed record preserves that presentation for
-- the client and save without changing the global tree terrain definition.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Restrict this feature-name override to the placed Jungle Book map.
local function dead_tree(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

handler.dead_tree = dead_tree

return handler
