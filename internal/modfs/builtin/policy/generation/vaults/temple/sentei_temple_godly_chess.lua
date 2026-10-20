-- Every chess-piece statue is still a granite statue. The source gives
-- those features a map-specific description for player inspection.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Name the existing statue feature without duplicating its glyph mapping.
local function configure(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.CHESS_PIECE_STATUE,
    })
end

handler.configure = configure

return handler
