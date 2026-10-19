-- Example: The church H cell decays into either a human or elf skeleton after the vault is built.
local effects = require("constants.vault_effects")

local handler = {}

-- The church H cell decays into either a human or elf skeleton after the vault is built.
local function schedule_skeleton_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "H",
        alternatives = "human skeleton / elf skeleton",
    })
end

handler.schedule_skeleton_decay = schedule_skeleton_decay

return handler
