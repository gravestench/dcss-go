-- Example: The abandoned market marks q for later deep dwarf skeleton decay after the map is placed.
local effects = require("constants.vault_effects")

local handler = {}

-- The abandoned market marks q for later deep dwarf skeleton decay after the map is placed.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "q",
        alternatives = "deep dwarf skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
