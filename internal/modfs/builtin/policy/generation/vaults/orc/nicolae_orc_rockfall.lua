-- The cave-in leaves an Orc corpse and loose rocks at its o glyph. Both
-- belong to one saved delayed-decay record so a restore cannot split them.
local effects = require("constants.vault_effects")

local handler = {}

-- Preserve the source's corpse and possible rock debris as one event.
local function schedule_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "o",
        alternatives = "orc corpse",
        extra_items = "stone q:1 / nothing, large rock q:1",
    })
end

handler.schedule_decay = schedule_decay

return handler
