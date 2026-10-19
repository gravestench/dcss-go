-- Example: Give the orb chamber statue its authored feature name when the vault record materializes.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Give the orb chamber statue its authored feature name when the vault record materializes.
local function name_orb_statue(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.HIDEOUS_STATUE,
    })
end

handler.name_orb_statue = name_orb_statue

return handler
