-- The source entrance leaves an old dwarf skeleton on each '%' marker.
-- Its corpse aging is a placed-vault record so the population owner can
-- materialize it after the entrance's terrain has been resolved.
local effects = require("constants.vault_effects")

local handler = {}

-- Record the source delayed-decay request at this DES declaration site.
local function delayed_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "%",
        alternatives = "dwarf skeleton",
    })
end

handler.delayed_decay = delayed_decay

return handler
