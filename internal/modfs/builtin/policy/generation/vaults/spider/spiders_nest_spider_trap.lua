-- Source places two one-shot player-move markers before it changes any
-- z terrain. Anchoring them now keeps their cells when SUBST erases z.
local effects = require("constants.vault_effects")
local triggers = require("constants.vault_triggers")

local handler = {}

-- The basket spawns awake redbacks; the entrance marker warns first.
-- Each marker becomes one saved ECS trigger during level population.
local function configure(api)
    api:record(effects.MARKER, {
        glyph = "z",
        identity = triggers.SPIDER_NEST_SPAWN,
    })
    api:record(effects.MARKER, {
        glyph = "Z",
        identity = triggers.SPIDER_NEST_WARN,
    })
end

handler.configure = configure

return handler
