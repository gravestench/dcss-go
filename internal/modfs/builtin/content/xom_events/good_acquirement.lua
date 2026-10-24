-- A high-severity item draw becomes source acquirement instead.
-- Selection stage 160 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_ACQUIREMENT,
    name = "Acquirement",
    side = sides.GOOD,
    effect_module = effects.ITEMS,
    selection_stage = 160,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
