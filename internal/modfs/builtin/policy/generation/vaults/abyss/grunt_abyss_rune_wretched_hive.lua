-- Theory of operation: grunt_abyss_rune_wretched_hive keeps source geometry in DES.
-- Named hooks preserve the source declaration positions and use
-- the ordinary vault operation stream for deterministic choices.
local effects = require("constants.vault_effects")

local handler = {}

-- Keep the source remains tied to their final resolved glyphs.
local function decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "1",
        alternatives = "deep elf demonologist corpse",
    })
end

handler.decay = decay

return handler
