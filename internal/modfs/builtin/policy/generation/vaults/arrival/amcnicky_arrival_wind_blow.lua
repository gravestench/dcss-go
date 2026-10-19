-- Example: The wind-blown arrival uses p as its delayed deep dwarf skeleton marker.
local effects = require("constants.vault_effects")

local handler = {}

-- The wind-blown arrival uses p as its delayed deep dwarf skeleton marker.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "p",
        alternatives = "deep dwarf skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
