-- wizlab_zonguldrok keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")
local wizlab = require("constants.wizlab")

local map = {}

-- The source installs the shared exit before grave substitutions, so
-- every authored < remains a live return arch after randomization.
function map.site_1(api)
    shared.setup(api)
end

-- Brown dead trees keep their base terrain; only inspection changes.
function map.site_2(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.TREE,
        name = names.DEAD_TREE,
    })
end

-- Draw the number of active graves once, then anchor each source event
-- callback as a typed marker. The live event owners persist counters,
-- door state, and ancient-lich awakening on Akara components.
function map.site_3(api)
    local graves = 28 + api:roll(4) + api:roll(4)

    api:emit(directives.NSUBST,
        "G = " .. graves .. ":G / *:.")
    local anchored = {
        {
            glyph = "G",
            identity = wizlab.ZONG_GRAVE_MARKER,
        },
        {
            glyph = "Z",
            identity = wizlab.ZONG_WIZARD_GRAVE_MARKER,
        },
        {
            glyph = "W",
            identity = wizlab.ZONG_SHRINE_MARKER,
        },
        {
            glyph = "M",
            identity = wizlab.ZONG_SPAWN_MARKER,
        },
        {
            glyph = "D",
            identity = wizlab.ZONG_DEATH_MARKER,
        },
        {
            glyph = "L",
            identity = wizlab.ZONG_AWAKEN_MARKER,
        },
    }

    for _, marker in ipairs(anchored) do
        api:record(effects.MARKER, marker)
    end
end

-- Source gravestones are granite statues with a local display name.
function map.site_4(api)
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.WIZLAB_GRAVESTONE,
    })
end

-- The source random roster ends in an empty slash; preserve the six
-- actual monster alternatives and their explicit late-undead weights.
function map.site_5(api)
    shared.random_monsters(api,
        "ogre zombie / troll zombie / two-headed ogre zombie / " ..
        "wight w:20 / vampire w:5 / skeletal warrior w:15")
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Zonguldrok's Shrine")
end

return map
