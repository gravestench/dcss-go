-- Xom can move the player to a useful landing on an unexplored floor.
-- Selection stage 170 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_TELEPORT,
    name = "Good teleportation",
    side = sides.GOOD,
    effect_module = effects.TELEPORT,
    selection_stage = 170,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
