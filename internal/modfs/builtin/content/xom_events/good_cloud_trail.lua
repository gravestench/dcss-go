-- A quiet turn can grant a lasting cloud trail rather than an immediate blast.
-- Selection stage 40 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_CLOUD_TRAIL,
    name = "Cloud trail",
    side = sides.GOOD,
    effect_module = effects.CLOUDS,
    selection_stage = 40,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
