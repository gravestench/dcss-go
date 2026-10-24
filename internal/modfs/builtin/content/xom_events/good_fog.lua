-- Fog only begins when the player's square is not already cloudy.
-- Selection stage 150 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_FOG,
    name = "Fog",
    side = sides.GOOD,
    effect_module = effects.CLOUDS,
    selection_stage = 150,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
