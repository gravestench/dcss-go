-- In danger, Xom can strengthen a nearby enemy.
-- Selection stage 30 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_ENCHANT_MONSTER,
    name = "Bad enchant monster",
    side = sides.BAD,
    effect_module = effects.MONSTER_ENCHANTMENT,
    selection_stage = 30,
    badness_10x = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
