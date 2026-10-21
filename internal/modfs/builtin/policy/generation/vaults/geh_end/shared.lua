-- Shared source helpers for the seven Gehenna seventh-floor controllers.
-- The DES files retain each call in its original script order.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local features = require("constants.vault_features")
local serpent_policy = require("policy.generation.hell.serpent")

local shared = {}

-- vault.lua chooses one Hell branch for the run and only places the Serpent
-- if it has not appeared already. The shared policy owns that saved state.
function shared.serpent(api)
    serpent_policy.setup(api, {
        glyph = "D",
        branch_id = branches.BRANCH_GEHENNA,
        monster_id = monsters.MONS_SERPENT_OF_HELL,
    })
end

-- Four source maps explicitly make the surrounding border endless lava.
function shared.border_fill(api)
    api:record(effects.BORDER_FILL, {
        style = fill.ENDLESS_LAVA,
    })
end

-- geh_setup in geh.des runs after each map's own directives. Its PLACE
-- declaration is static in the DES so primary selection sees the controller.
function shared.setup(api)
    api:emit(directives.KMASK, "O = no_item_gen")
    api:emit(directives.KITEM, "O = obsidian rune of Zot")
    api:emit(directives.LROCKCOL, "brown")
    api:emit(directives.LFLOORCOL, "lightgrey")
    api:emit(directives.LFLOORTILE, "floor_pebble_darkgray")
    api:emit(directives.COLOUR, "v = red")
    api:record(effects.FEATURE_NAME, {
        feature = "floor",
        name = "Ashen ground",
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.METAL_WALL,
        name = "tempered metal wall",
    })
end

return shared
