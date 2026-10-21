-- The tribal feast's fog machine stays in DES. Two authored skeleton
-- sites become typed delayed-decay records consumed by the live owner.
local effects = require("constants.vault_effects")

local remains = {}

-- Keep each species on its own source glyph after map substitutions.
local function schedule(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "d",
        alternatives = "yak skeleton",
    })
    api:record(effects.DELAYED_DECAY, {
        glyph = "e",
        alternatives = "rat skeleton",
    })
end

remains.schedule = schedule

return remains
