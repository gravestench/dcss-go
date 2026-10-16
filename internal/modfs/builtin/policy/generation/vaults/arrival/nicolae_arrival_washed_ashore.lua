local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Port of arrival/small.des:2995.
local function name_wreckage(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.WRECKAGE,
    })
end

handler.name_wreckage = name_wreckage

return handler
