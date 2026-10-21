-- The temple's corpses age according to the source delayed-decay item list.
local effects = require("constants.vault_effects")

local handler = {}

-- Save the source's weighted corpse and skeleton request on each d glyph.
local function delayed_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "d",
        alternatives = "base draconian corpse w:5 / " ..
            "base draconian skeleton / " ..
            "shadow dragon corpse w:5 / shadow dragon skeleton",
    })
end

handler.delayed_decay = delayed_decay

return handler
