-- The source gauntlet shares one repeated trigger across six glyphs. Keep
-- its wall targets as oriented marker records for the named world callback.
local effects = require("constants.vault_effects")

local handler = {}

-- Anchor source glyphs before SUBST turns d/e into displayed terrain.
local function trap_markers(api)
    for _, glyph in ipairs({ ":", "H", "-", "1", "e", "}" }) do
        api:record(effects.MARKER, {
            glyph = glyph,
            identity = "vault_trigger:tar.gauntlet_activate",
        })
    end

    api:record(effects.MARKER, {
        glyph = "d",
        identity = "vault_trigger:tar.trap_wall",
    })
    api:record(effects.MARKER, {
        glyph = '"',
        identity = "vault_trigger:tar.trap_wall2",
    })
end

handler.trap_markers = trap_markers

return handler
