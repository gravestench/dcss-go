-- The grave entrance keeps granite statues as terrain while describing
-- them as gravestones only inside this authored map. The generated level
-- retains the typed name request for the presentation owner.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Place the source's feature-name request at its original declaration
-- point, before the common Depths entry setup supplies its keyed gate.
local function rename_gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

handler.rename_gravestone = rename_gravestone

return handler
