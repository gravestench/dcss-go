-- A harmful polymorph changes a nearby monster or the player.
-- Selection stage 90 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_POLYMORPH,
    name = "Bad polymorph",
    side = sides.BAD,
    effect_module = effects.MONSTER_POLYMORPH,
    selection_stage = 90,
    badness_10x = 30,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
