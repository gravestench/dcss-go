-- Theory of operation: the dance floor's D and E glyphs represent fresh
-- remains after substitutions. Record the source delayed-decay instruction
-- before those glyphs receive their final terrain and presentation rules.
local effects = require("constants.vault_effects")

local handler = {}

-- Preserve corpse decay as level intent, including its random corpse choice.
local function decay_dancers(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "DE",
        alternatives = "random corpse",
    })
end

handler.decay_dancers = decay_dancers

return handler
