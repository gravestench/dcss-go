-- Rearranging nearby actors can place the player in danger.
-- Selection stage 60 is gameplay priority, independent of file load order.
local categories = require("constants.catalog")
local effects = require("constants.xom_effect_modules")
local events = require("ids.xom_events")
local sides = require("constants.xom_sides")

local definition = {
    id = events.BAD_SWAP_MONSTERS,
    name = "Swap monsters",
    side = sides.BAD,
    effect_module = effects.MONSTER_MOVEMENT,
    selection_stage = 60,
    badness_10x = 20,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
