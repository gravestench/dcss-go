-- Higher tension permits Xom to bring a group of allies.
-- Selection stage 100 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_ALLIES,
    name = "Summon allies",
    side = sides.GOOD,
    effect_module = effects.SUMMONS,
    selection_stage = 100,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
