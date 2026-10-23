-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local effects = require("constants.vault_effects")

local handler = {}

-- Record delayed decay so remains are placed after terrain resolves.
-- Source operation:
-- : dgn.delayed_decay(_G, 'd', 'human corpse')
local function preserve_corpses(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "d",
        alternatives = "human corpse",
    })
end

handler.preserve_corpses = preserve_corpses

return handler
