-- wizlab_cloud keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local map = {}

-- Draw the Cloud Mage's name once, before placing its keyed slot. The
-- source display name travels with this one actor, not the monster type.
function map.site_1(api)
    local name = api:random_name():gsub(" ", "_")

    api:emit(directives.KMONS,
        "5 = patrolling Cloud Mage dbname:Cloud_Mage name:" ..
        name .. " ; robe_of_clouds . quick blade ego:electrocution " ..
        "| dagger ego:electrocution | staff of air")
end

-- Open sea surrounds the authored cloud chamber. The source roster
-- remains available for random summons despite no ambient generation.
function map.site_2(api)
    api:record(effects.BORDER_FILL, {
        style = fill.OPEN_SEA,
    })
    shared.random_monsters(api,
        "air elemental w:40 / shock serpent / spark wasp / " ..
        "wind drake / ghost crab / apocalypse crab / " ..
        "spriggan air mage / blizzard demon")
    shared.setup(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.FLOOR,
        name = names.WIZLAB_DAMP_FLOOR,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.CRYSTAL_WALL,
        name = names.WHITE_CRYSTAL_WALL,
    })
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "The Chambers of the Cloud Mage")
end

return map
