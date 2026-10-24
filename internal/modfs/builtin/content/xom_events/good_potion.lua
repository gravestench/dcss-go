-- The first good combat check can rescue Xom's worshipper with a potion effect.
-- Selection stage 10 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_POTION,
    name = "Potion",
    side = sides.GOOD,
    effect_module = effects.POTION,
    selection_stage = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
