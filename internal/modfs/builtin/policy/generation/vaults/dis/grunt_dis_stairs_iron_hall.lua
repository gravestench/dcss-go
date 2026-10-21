-- The source hall arms one shared movement event around trap statues.
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local names = require("constants.vault_feature_names")

local handler = {}

-- Anchor every source trigger glyph before d/e/f substitutions. The G
-- markers remain separate targets for the later one-in-four golem rolls.
function handler.configure_trigger(api)
    for _, glyph in ipairs({ ":", "1", "2", "d", "e", "f", "}" }) do
        api:record(effects.MARKER, {
            glyph = glyph,
            identity = "vault_trigger:dis.iron_hall_animate",
        })
    end

    api:record(effects.MARKER, {
        glyph = "G",
        identity = "vault_trigger:dis.trap_statue",
    })
    api:record(effects.MARKER, {
        glyph = "G",
        identity = 'lua:props_marker {trap_statue=1,veto_destroy="veto"}',
    })
    api:record(effects.FEATURE_NAME, {
        feature = features.GRANITE_STATUE,
        name = names.IRON_STATUE,
    })
end

return handler
