-- A tense fight can grant a brief cleaving effect.
-- Selection stage 140 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_CLEAVING,
    name = "Cleaving",
    side = sides.GOOD,
    effect_module = effects.COMBAT,
    selection_stage = 140,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
