-- Shared source helpers for Dis's seventh-floor controllers and child maps.
-- Keep their effects at the same script sites as branches/dis.des.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local triggers = require("constants.vault_triggers")
local serpent = require("policy.generation.hell.serpent")

local handler = {}

-- Both dis_setup and dis_statues rename only this map's granite statues.
function handler.iron_statue_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.IRON_STATUE,
    })
end

-- The source's soh_hangout chooses one persistent Hell branch. The shared
-- Lua policy reads that saved choice and the Serpent's unique history.
function handler.serpent_of_hell(api)
    serpent.setup(api, {
        glyph = "D",
        branch_id = branches.BRANCH_DIS,
        monster_id = monsters.MONS_SERPENT_OF_HELL,
    })
end

-- The animated statues awaken as iron golems when Dispater dies. The marker
-- remains an authored source marker; its event behavior belongs to the
-- world's marker runtime, after the map has been placed.
function handler.mu_statue_marker(api)
    api:record(effects.MARKER, {
        glyph = "o",
        identity = triggers.DIS_MU_STATUE_AWAKEN,
        event = triggers.MONSTER_DEATH_EVENT,
    })
end

return handler
