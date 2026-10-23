-- wizlab_wucad keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fill = require("constants.vault_border_fill")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local wizlab = require("constants.wizlab")

local map = {}

-- Seven numbered source positions drive one-shot shadow messages.
-- The A anchor owns both the periodic monk timer and the named statue
-- death trigger; live event systems interpret these saved marker kinds.
function map.site_1(api)
    for spot = 1, 7 do
        api:emit(directives.MARKER,
            spot .. " = " .. wizlab.WUCAD_MESSAGE_MARKER ..
            " { spot = " .. spot .. " }")
    end

    api:emit(directives.MARKER,
        "A = " .. wizlab.WUCAD_MONKS_MARKER)
    api:emit(directives.MARKER,
        "A = " .. wizlab.WUCAD_DEATH_MARKER)
end

-- The source tree border and graveyard roster are level intent, while
-- inspection names annotate existing terrain without changing collision.
function map.site_2(api)
    shared.setup(api)
    api:record(effects.BORDER_FILL, {
        style = fill.TREE,
    })
    shared.random_monsters(api,
        "shadow w:6 / flayed ghost w:2 / wraith w:2 / " ..
        "demonspawn / deep troll / grey draconian monk w:6")
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.WIZLAB_AUTUMNAL_TREE,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.STONE_WALL,
        name = names.WIZLAB_CRUMBLED_STONE_WALL,
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.WIZLAB_STRANGE_STATUE,
    })
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Wucad Mu's Monastery")
end

return map
