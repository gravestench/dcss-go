-- Example: Name the warning statue at its feature record so the Sigmund hint survives terrain projection.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Name the warning statue at its feature record so the Sigmund hint survives terrain projection.
local function name_warning_statue(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.WARNING_STATUE,
    })
end

handler.name_warning_statue = name_warning_statue

return handler
