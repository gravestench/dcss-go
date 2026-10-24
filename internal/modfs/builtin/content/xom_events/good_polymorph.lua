-- Xom can change a nearby monster into a more useful form.
-- Selection stage 120 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_POLYMORPH,
    name = "Good polymorph",
    side = sides.GOOD,
    effect_module = effects.MONSTER_POLYMORPH,
    selection_stage = 120,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
