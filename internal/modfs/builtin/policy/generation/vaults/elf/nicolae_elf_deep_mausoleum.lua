-- The gravestones use ordinary granite statue terrain. A typed local
-- feature-name record changes their description only in this map.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Preserve the source's custom gravestone text without renaming every
-- granite statue in other vaults or branches.
local function rename_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

handler.rename_gravestone = rename_gravestone

return handler
