-- A severe bad roll can send the player to the Abyss.
-- Selection stage 150 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_BANISHMENT,
    name = "Banishment",
    side = sides.BAD,
    effect_module = effects.TRAVEL,
    selection_stage = 150,
    badness_10x = 50,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
