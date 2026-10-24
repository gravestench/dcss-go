-- The same late roll can drain life force when resistance allows.
-- Selection stage 130 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_DRAINING,
    name = "Draining",
    side = sides.BAD,
    effect_module = effects.STATUS,
    selection_stage = 130,
    badness_10x = 23,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
