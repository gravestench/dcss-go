local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Port of arrival/small.des:3262.
local function name_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

handler.name_gravestone = name_gravestone

return handler
