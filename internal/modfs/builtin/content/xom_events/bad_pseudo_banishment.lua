-- The banishment draw may instead return the player immediately.
-- Selection stage 150 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_PSEUDO_BANISHMENT,
    name = "Pseudo banishment",
    side = sides.BAD,
    effect_module = effects.TRAVEL,
    selection_stage = 150,
    badness_10x = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
