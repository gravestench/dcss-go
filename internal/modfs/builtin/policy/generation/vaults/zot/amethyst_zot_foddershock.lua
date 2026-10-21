-- The shock scene begins with old draconian remains at its a cells.
-- Save the source intent as a typed effect rather than placing a corpse
-- from a process global while generating the map.
local effects = require("constants.vault_effects")

local handler = {}

-- The shared delayed-decay consumer decides the final corpse age after
-- the map's orientation and substitutions establish its world cells.
local function deferred_corpse_decay(api)
    api:record(effects.DELAYED_DECAY, {
        glyph = "a",
        alternatives = "random draconian corpse",
    })
end

handler.deferred_corpse_decay = deferred_corpse_decay

return handler
