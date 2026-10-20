-- This rare Jiyva Temple decorates stone walls with rune carvings. Naming
-- is source map data and must survive until inspection after placement.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Attach the source wall description at its Lua hook position.
local function configure(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = names.RUNE_CARVED_STONE_WALL,
    })
end

handler.configure = configure

return handler
