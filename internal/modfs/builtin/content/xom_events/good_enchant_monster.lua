-- A nearby enchantable foe gives Xom a target for helpful enchantment.
-- Selection stage 60 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.GOOD_ENCHANT_MONSTER,
    name = "Enchant monster",
    side = sides.GOOD,
    effect_module = effects.MONSTER_ENCHANTMENT,
    selection_stage = 60,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
