-- Noise can occur even outside combat and wakes nearby listeners.
-- Selection stage 20 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_NOISE,
    name = "Noise",
    side = sides.BAD,
    effect_module = effects.STATUS,
    selection_stage = 20,
    badness_10x = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
