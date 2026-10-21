-- The authored river contains bat remains at its e glyph. Generation
-- records that history; the existing decay owner materializes it later.
local effects = require("constants.vault_effects")

local handler = {}

-- Keep the source corpse attached to the map's substituted e cells.
local function schedule_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "e",
        alternatives = "bat corpse",
    })
end

handler.schedule_decay = schedule_decay

return handler
