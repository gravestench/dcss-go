-- A bad action can create real hostile summons around the player.
-- Selection stage 120 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_SUMMON_HOSTILES,
    name = "Summon hostiles",
    side = sides.BAD,
    effect_module = effects.SUMMONS,
    selection_stage = 120,
    badness_10x = 35,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
