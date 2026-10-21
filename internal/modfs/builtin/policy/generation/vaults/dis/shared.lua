-- Dis's granite statues use iron coloring and tiles in DES. The source
-- display name is applied per selected map so other branches keep theirs.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Keep the source set_feature_name call local to the authored Dis map.
function handler.iron_statue_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.IRON_STATUE,
    })
end

return handler
