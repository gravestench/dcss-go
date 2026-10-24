-- Xom can relocate nearby monsters to worsen positioning.
-- Selection stage 40 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_BLINK_MONSTERS,
    name = "Blink monsters",
    side = sides.BAD,
    effect_module = effects.MONSTER_MOVEMENT,
    selection_stage = 40,
    badness_10x = 10,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
