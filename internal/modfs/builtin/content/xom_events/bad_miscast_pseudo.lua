-- A mild bad roll may sound like a miscast without its damaging effect.
-- Selection stage 10 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_MISCAST_PSEUDO,
    name = "Pseudo miscast",
    side = sides.BAD,
    effect_module = effects.STATUS,
    selection_stage = 10,
    badness_10x = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
