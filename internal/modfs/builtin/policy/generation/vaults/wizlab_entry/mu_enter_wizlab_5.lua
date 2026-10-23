-- The fifth source entrance names its magenta crystal walls differently
-- from ordinary crystal terrain. Keep that presentation record beside
-- the map that authored it; collision still reads the base terrain ID.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local shared = require("policy.generation.vaults.wizlab_entry.shared")

local map = {}

-- Run the common gate first because the source declared its wall name
-- after wizlab_portal, preserving each emitted record's source position.
function map.site_1(api)
    shared.portal(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.CRYSTAL_WALL,
        name = names.WIZLAB_CRYSTAL_WALL,
    })
end

return map
