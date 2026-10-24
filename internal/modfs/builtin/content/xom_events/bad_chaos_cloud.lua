-- A hostile chaos cloud starts only on an unclouded player square.
-- Selection stage 140 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_CHAOS_CLOUD,
    name = "Chaos cloud",
    side = sides.BAD,
    effect_module = effects.CLOUDS,
    selection_stage = 140,
    badness_10x = 20,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
