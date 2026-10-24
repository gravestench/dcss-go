-- Real destruction damages targets outside the player's adjacent ring.
-- Selection stage 130 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_DESTRUCTION,
    name = "Mass fireball",
    side = sides.GOOD,
    effect_module = effects.COMBAT,
    selection_stage = 130,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
