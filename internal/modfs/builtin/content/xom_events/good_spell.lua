-- A dangerous fight can prompt one of Xom's source spell choices.
-- Selection stage 30 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_SPELL,
    name = "Tension spell",
    side = sides.GOOD,
    effect_module = effects.SPELL,
    selection_stage = 30,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
