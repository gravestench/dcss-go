-- Bad teleportation weighs exploration and current danger.
-- Selection stage 80 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_TELEPORT,
    name = "Bad teleportation",
    side = sides.BAD,
    effect_module = effects.TELEPORT,
    selection_stage = 80,
    dynamic_badness = "terrain",
}

register.definition(categories.XOM_EVENTS, definition)

return definition
