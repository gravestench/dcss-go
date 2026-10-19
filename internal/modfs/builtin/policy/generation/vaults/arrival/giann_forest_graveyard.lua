-- Example: The graveyard h glyph becomes human skeleton remains through delayed decay.
local effects = require("constants.vault_effects")

local handler = {}

-- The graveyard h glyph becomes human skeleton remains through delayed decay.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "h",
        alternatives = "human skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
