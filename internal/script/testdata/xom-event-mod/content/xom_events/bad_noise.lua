-- Replacing the same relative path changes this source event's metadata.
local categories = require("constants.catalog")
local ids = require("ids.xom_events")

local definition = {
    id = ids.BAD_NOISE,
    name = "Modified noise",
    side = "bad",
    effect_module = "policy.religion.xom.mod_effect",
    badness_10x = 70,
    selection_stage = 20,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
