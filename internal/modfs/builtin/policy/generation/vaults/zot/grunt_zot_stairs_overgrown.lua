-- Source overgrown stairs attach one LOS start marker and one repeated turn
-- marker before SHUFFLE moves the visible stair glyphs. Keep those marker
-- cells typed so the live world owner can save the countdown independently.
local effects = require("constants.vault_effects")
local triggers = require("constants.vault_triggers")

local handler = {}

-- Anchor each source marker to its original glyph before substitutions;
-- the placement engine rotates its final coordinate with the vault.
local function configure_trigger(api)
    api:record(effects.MARKER, {
        glyph = "1",
        identity = triggers.ZOT_OVERGROWN_START,
    })

    api:record(effects.MARKER, {
        glyph = "}",
        identity = triggers.ZOT_OVERGROWN_TICK,
    })
end

handler.configure_trigger = configure_trigger

return handler
