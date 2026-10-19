-- Example: The moat vault labels granite statues as gravestones when feature names are projected.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- The moat vault labels granite statues as gravestones when feature names are projected.
local function name_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.ADVENTURERS_GRAVESTONE,
    })
end

handler.name_gravestone = name_gravestone

return handler
