-- This same-path file replaces only the vampire castle's local hooks.
-- Its marker proves the effective VFS module ran at the source hook site.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local castle = {}

-- The marker is an inspectable witness for the override test. In a real
-- mod, a handler here can replace the delayed decay policy for this map.
local function decay(api)
    api:record(effects.MARKER, {
        glyph = "f",
        identity = "bailey_mod_hook_witness",
    })
end

-- Keep the two other source hooks so this small override retains their
-- intended local names while changing the decay behavior alone.
local function dead_tree(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

-- This is a map-local statue label, not a global terrain name change.
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
