local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Port of arrival/small.des:3625.
local function name_warning_statue(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.WARNING_STATUE,
    })
end

handler.name_warning_statue = name_warning_statue

return handler
