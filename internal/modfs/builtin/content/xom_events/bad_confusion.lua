-- Confusion is reserved for a fight where it can matter.
-- Selection stage 50 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_CONFUSION,
    name = "Confuse player",
    side = sides.BAD,
    effect_module = effects.STATUS,
    selection_stage = 50,
    badness_10x = 13,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
