-- Dis's iron temple retains the source granite statue terrain and tile,
-- but changes the local display name to match its iron guardians.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- The rename applies only to this selected child map, not every granite
-- statue in the branch or the rest of the game.
local function feature_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.IRON_STATUE,
    })
end

handler.feature_name = feature_name

return handler
