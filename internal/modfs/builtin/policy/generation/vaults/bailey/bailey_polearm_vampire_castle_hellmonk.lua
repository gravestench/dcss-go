-- The vampire castle adds one delayed skeleton group and two local
-- feature names. They are saved placement records, so reloading the
-- temporary floor does not rerun a source hook or forget its decoration.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local castle = {}

-- Source dgn.delayed_decay asks population to age skeletons on `f`
-- cells after geometry and substitutions have resolved.
local function decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "f",
        alternatives = "orc skeleton",
    })
end

-- A dead tree is still tree terrain. Its map-local name is presentation
-- intent rather than a second terrain type or a global renaming rule.
local function dead_tree(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

-- Gravestones are granite statue terrain with a source-specific name;
-- keeping the record local avoids changing unrelated statues.
local function gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.GRAVESTONE,
    })
end

castle.decay = decay
castle.dead_tree = dead_tree
castle.gravestone = gravestone

return castle
