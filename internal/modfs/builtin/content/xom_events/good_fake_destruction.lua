-- The same selection gate can make a harmless theatrical blast.
-- Selection stage 130 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_FAKE_DESTRUCTION,
    name = "Fake fireball",
    side = sides.GOOD,
    effect_module = effects.COMBAT,
    selection_stage = 130,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
