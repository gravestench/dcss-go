local effects = require("constants.vault_effects")

local handler = {}

-- Port of arrival/simple.des:2137.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "h",
        alternatives = "human skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
