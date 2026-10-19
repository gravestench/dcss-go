-- Example: Name TREE features as dead trees for the xxxplode arrival without changing their terrain ID.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Name TREE features as dead trees for the xxxplode arrival without changing their terrain ID.
local function name_dead_trees(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

handler.name_dead_trees = name_dead_trees

return handler
