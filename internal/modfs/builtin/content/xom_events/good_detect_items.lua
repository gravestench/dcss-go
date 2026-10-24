-- Item detection shares the divination draw but checks exploration first.
-- Selection stage 20 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_DETECT_ITEMS,
    name = "Detect items",
    side = sides.GOOD,
    effect_module = effects.DIVINATION,
    selection_stage = 20,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
