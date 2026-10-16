local effects = require("constants.vault_effects")

local handler = {}

-- Port of arrival/small.des:3571.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "q",
        alternatives = "deep dwarf skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
