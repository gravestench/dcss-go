local effects = require("constants.vault_effects")

local handler = {}

-- Port of builder/shops.des:492.
local function decay_corpse(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "Z",
        alternatives = "human corpse",
    })
end

handler.decay_corpse = decay_corpse

return handler
