-- Nearby enemies allow Xom's late good roll to strike with lightning.
-- Selection stage 190 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_LIGHTNING,
    name = "Lightning",
    side = sides.GOOD,
    effect_module = effects.COMBAT,
    selection_stage = 190,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
