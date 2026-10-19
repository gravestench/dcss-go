-- Example: The lonely grave names its granite statue as a gravestone at feature materialization.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- The lonely grave names its granite statue as a gravestone at feature materialization.
local function name_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

handler.name_gravestone = name_gravestone

return handler
