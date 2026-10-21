-- Theory of operation: a Vaults room can name decorative terrain without
-- changing the underlying feature used for collision and travel. The DES
-- hook emits a typed record so save/restore retains that authored name.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Gozag's gold statue is still granite terrain. The display name explains
-- the room's art while other terrain rules continue to see granite.
local function golden_statue(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GOLDEN_STATUE,
    })
end

handler.golden_statue = golden_statue

return handler
