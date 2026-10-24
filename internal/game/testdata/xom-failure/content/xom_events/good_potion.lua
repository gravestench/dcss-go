-- The overlay replaces one event definition, leaving the action owner live.
local categories = require("constants.catalog")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_POTION,
    name = "Broken modded potion",
    side = sides.GOOD,
    effect_module = "policy.religion.xom.broken_effect",
    selection_stage = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
