-- wizlab_demon keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local map = {}

-- The named Hellbinder's artifact remains its fixed equipment; only
-- the person's displayed name is drawn before its KMONS declaration.
function map.site_1(api)
    local name = api:random_name():gsub(" ", "_")

    api:emit(directives.KMONS,
        "4 = patrolling Hellbinder dbname:Hellbinder name:" ..
        name .. " ; majin-bo")
end

-- Summoning uses this demon roster; the keyed sigil guardians and
-- Hellbinder remain independent authored actors in the DES map.
function map.site_2(api)
    shared.random_monsters(api,
        "common demon w:200 / balrug / blizzard demon / " ..
        "cacodemon / green death / hell beast / hellion / " ..
        "lorocyproca / shadow demon / tormentor / " ..
        "demonspawn blood saint w:5 / demonspawn black sun w:5")
    shared.setup(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = names.WIZLAB_BLACK_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.ROCK_WALL,
        name = names.WIZLAB_CARVED_ROCK_WALL,
    })
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "The Hall of the Hellbinder")
end

return map
