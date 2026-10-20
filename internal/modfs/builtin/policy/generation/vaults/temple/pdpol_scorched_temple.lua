-- The scorched Temple's granite statues are broken pillars. This custom
-- name is attached to the feature identity rather than repeated at cells.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Preserve the authored pillar description for later inspection.
local function configure(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.BROKEN_PILLAR,
    })
end

handler.configure = configure

return handler
