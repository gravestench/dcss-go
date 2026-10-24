-- A source-eligible monster can receive chaotic gear and power.
-- Selection stage 70 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_CHAOS_UPGRADE,
    name = "Chaos upgrade",
    side = sides.BAD,
    effect_module = effects.MONSTER_CHAOS_UPGRADE,
    selection_stage = 70,
    badness_10x = 20,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
