-- A stair underfoot can become temporarily impossible to climb.
-- Selection stage 100 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_CLIMB_STAIRS,
    name = "Unclimbable stairs",
    side = sides.BAD,
    effect_module = effects.STAIRS,
    selection_stage = 100,
    badness_10x = 30,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
