-- Theory of operation: the source Lady of the Lake has two player-move
-- trigger glyph types but one shared, one-shot avatar. The O and : cells mark
-- encounter entrances; K is the deep-water spawn target. Anchor all three
-- before MAP substitutions so orientation later moves them together.
local effects = require("constants.vault_effects")
local triggers = require("constants.vault_triggers")

local handler = {}

-- Save source marker intent; the gameplay callback runs only after entry.
local function configure_trigger(api)
    api:record(effects.MARKER, {
        glyph = "O",
        identity = triggers.LADY_OF_LAKE_SPAWN,
    })
    api:record(effects.MARKER, {
        glyph = ":",
        identity = triggers.LADY_OF_LAKE_SPAWN,
    })
    api:record(effects.MARKER, {
        glyph = "K",
        identity = triggers.MERFOLK_AVATAR_TARGET,
    })
end

handler.configure_trigger = configure_trigger

return handler
