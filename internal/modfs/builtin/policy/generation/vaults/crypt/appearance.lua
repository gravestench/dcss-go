-- These Crypt descriptions belong to the placed map. They become typed
-- records, so a dead tree never renames every tree in the game.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local appearance = {}

-- Keep tree collision and sight behavior while giving the dead forest its
-- source name on inspection and after save/restore.
function appearance.dead_tree(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

-- A Crypt gravestone is still a granite statue for terrain rules; only
-- its local player-facing description changes.
function appearance.gravestone(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.CRYPT_GRAVESTONE,
    })
end

-- The guarded arrival uses statue terrain as sealed sarcophagi until its
-- one-shot line-of-sight event changes the individual cells.
function appearance.sarcophagus(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.SARCOPHAGUS,
    })
end

return appearance
