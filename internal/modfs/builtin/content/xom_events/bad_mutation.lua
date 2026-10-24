-- Xom may impose an acquired mutation when the body can change.
-- Selection stage 110 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_MUTATION,
    name = "Bad mutations",
    side = sides.BAD,
    effect_module = effects.MUTATIONS,
    selection_stage = 110,
    badness_10x = 30,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
