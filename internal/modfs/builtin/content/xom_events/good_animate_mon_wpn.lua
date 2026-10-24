-- A nearby wielded weapon can become Xom's temporary ally.
-- Selection stage 110 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_ANIMATE_MON_WPN,
    name = "Animate monster weapon",
    side = sides.GOOD,
    effect_module = effects.ANIMATE_WEAPON,
    selection_stage = 110,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
