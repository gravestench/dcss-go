-- Example: The bloodbath corpse is scheduled for decay after shop terrain and stock are placed.
local effects = require("constants.vault_effects")

local handler = {}

-- The bloodbath corpse is scheduled for decay after shop terrain and stock are placed.
local function decay_corpse(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "Z",
        alternatives = "human corpse",
    })
end

handler.decay_corpse = decay_corpse

return handler
