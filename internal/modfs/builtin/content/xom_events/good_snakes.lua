-- A hostile snake can become a stick through Xom's transformation.
-- Selection stage 90 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_SNAKES,
    name = "Snakes to sticks",
    side = sides.GOOD,
    effect_module = effects.MONSTER_SNAKES,
    selection_stage = 90,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
