-- The lost-world cave starts with an aged human skeleton on its C cell.
-- Delayed decay is a typed placement record, not a startup side effect.
local effects = require("constants.vault_effects")

local lost_world = {}

-- The shared population owner resolves this source glyph after all map
-- substitutions so save/restore preserves the same corpse stage.
local function delayed_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "C",
        alternatives = "human skeleton",
    })
end

lost_world.site_1 = delayed_decay

return lost_world
