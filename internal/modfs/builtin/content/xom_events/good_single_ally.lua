-- One ally is the early summon branch when the fight is tense enough.
-- Selection stage 70 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_SINGLE_ALLY,
    name = "Single ally",
    side = sides.GOOD,
    effect_module = effects.SUMMONS,
    selection_stage = 70,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
