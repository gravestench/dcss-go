local effects = require("constants.vault_effects")

local handler = {}

-- Port of arrival/large.des:1129.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "H",
        alternatives = "human skeleton / elf skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
