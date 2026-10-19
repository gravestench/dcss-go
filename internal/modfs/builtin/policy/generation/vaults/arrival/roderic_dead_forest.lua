-- Example: Dead forest trees use a feature-name effect rather than replacing the underlying TREE feature.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Dead forest trees use a feature-name effect rather than replacing the underlying TREE feature.
local function name_dead_trees(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

handler.name_dead_trees = name_dead_trees

return handler
