-- Source Volcano maps call these focused helpers at their original DES
-- sites. Each one emits normal typed directives; no mutable state lives
-- in this module between maps or games.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local fog = require("policy.generation.vaults.volcano.fog")
local guardians = require("policy.generation.vaults.volcano.guardians")
local loot = require("policy.generation.vaults.volcano.loot")
local volcano = require("constants.volcano")

local shared = {}

-- Every destination gets the source rewards, return arches, trap,
-- substitution palette, lava colours, and blocked-tunnel description.
local function setup(api)
    loot.setup(api)
    api:emit(directives.KFEAT,
        "< = " .. volcano.EXIT_FEATURE)
    api:emit(directives.KFEAT,
        "I = " .. volcano.EXIT_FEATURE)
    api:emit(directives.KFEAT, "^ = alarm trap")
    api:emit(directives.SUBST, "L : LLL.l")
    api:emit(directives.SUBST, "L = lll.")
    api:emit(directives.SUBST, "y : yyy.x")
    api:emit(directives.SUBST, "y = xxx.")
    api:emit(directives.COLOUR, "c = lightred")
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_ARCH,
        name = "rock-blocked tunnel",
    })
end

-- The bunker marks its transparent rock as a named glass window rather
-- than changing what the generic grid considers walkable or opaque.
local function window_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.CLEAR_ROCK_WALL,
        name = "glass window",
    })
end

shared.setup = setup
shared.window_name = window_name
shared.guardians = guardians.ordinary
shared.guardians_intelligent = guardians.intelligent
shared.guardians_village = guardians.village
shared.fog_tiny = fog.tiny
shared.fog_small = fog.small
shared.fog_large = fog.large
shared.fog_chained = fog.chained
shared.fog_lake = fog.lake

return shared
