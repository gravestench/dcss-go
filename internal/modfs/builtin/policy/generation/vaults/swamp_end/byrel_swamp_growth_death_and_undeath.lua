-- Theory of operation: the undead half begins with a hydra corpse at q.
-- DCSS delays its decay until the player enters the area. Preserve that
-- delayed item as typed level intent at the original source script site.
local effects = require("constants.vault_effects")

local handler = {}

-- The existing delayed-decay resolver owns both corpse placement and its
-- arrival trigger; this hook only names the authored glyph and species.
local function schedule_hydra_corpse(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "q",
        alternatives = "hydra corpse",
    })
end

handler.schedule_hydra_corpse = schedule_hydra_corpse

return handler
