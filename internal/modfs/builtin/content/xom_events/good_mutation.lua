-- Xom may alter a safely mutable character in a quiet moment.
-- Selection stage 180 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_MUTATION,
    name = "Good mutations",
    side = sides.GOOD,
    effect_module = effects.MUTATIONS,
    selection_stage = 180,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
