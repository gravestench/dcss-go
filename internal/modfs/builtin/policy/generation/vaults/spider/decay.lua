-- Creepy Crawlies and the three mines request remains at authored cells.
-- The common typed effect handles both placing the remains and aging them.
local effects = require("constants.vault_effects")

local handler = {}

-- Any eligible corpse follows the source % marker in Creepy Crawlies.
local function any_corpse(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "%",
        alternatives = "any corpse",
    })
end

-- The mines' v cells all carry old orc skeletons from the same source rule.
local function orc_skeleton(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "v",
        alternatives = "orc skeleton",
    })
end

handler.any_corpse = any_corpse
handler.orc_skeleton = orc_skeleton

return handler
