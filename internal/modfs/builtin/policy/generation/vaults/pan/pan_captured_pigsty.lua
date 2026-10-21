-- The source map's inline callback becomes saved marker properties. The
-- combat death hook finds the exact actor and grate through these records;
-- neither callback code nor process-global state enters the save.
local effects = require("constants.vault_effects")
local pigsty = require("constants.pan_pigsty")

local handler = {}

-- Anchor the callback marker on glyph 1 and the gate marker on glyph o
-- before projection, so both positions follow the map's chosen rotation.
local function markers(api)
    api:record(effects.MARKER, {
        glyph = "1",
        identity = "pan:swineherd",
        [pigsty.SWINEHERD_PROPERTY] = pigsty.SWINEHERD_VALUE,
    })
    api:record(effects.MARKER, {
        glyph = "o",
        identity = "pan:pigsty_gate",
        [pigsty.GATE_PROPERTY] = pigsty.GATE_VALUE,
    })
end

handler.markers = markers

return handler
