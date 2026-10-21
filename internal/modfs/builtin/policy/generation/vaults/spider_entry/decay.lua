-- The ruined Spider gate includes redback remains. Source delayed decay
-- waits until the map is placed, so the corpse follows its final % cell.
local effects = require("constants.vault_effects")

local handler = {}

-- Keep corpse creation and its later decay tied to the selected source map.
local function redback(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "%",
        alternatives = "redback corpse",
    })
end

handler.redback = redback

return handler
