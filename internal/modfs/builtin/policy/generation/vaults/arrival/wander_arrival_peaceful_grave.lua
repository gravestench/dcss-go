-- Example: The peaceful grave gives the same terrain feature a gravestone name for this map.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- The peaceful grave gives the same terrain feature a gravestone name for this map.
local function name_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

handler.name_gravestone = name_gravestone

return handler
