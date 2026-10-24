-- Xom may confuse nearby foes when the player faces danger.
-- Selection stage 50 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_CONFUSION,
    name = "Confuse monsters",
    side = sides.GOOD,
    effect_module = effects.MONSTER_CONFUSION,
    selection_stage = 50,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
