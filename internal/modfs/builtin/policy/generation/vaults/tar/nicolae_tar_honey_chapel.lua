-- One source coin flip makes the chapel's pillars visibly broken.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Use one saved layout draw for both the tile and its matching feature name.
local function pillar_choice(api)
    if not api:coinflip() then
        return
    end

    api:emit(directives.TILE, "G = dngn_crumbled_column")
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.BROKEN_PILLAR,
    })
end

handler.pillar_choice = pillar_choice

return handler
