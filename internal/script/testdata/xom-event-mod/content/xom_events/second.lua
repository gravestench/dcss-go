-- This event succeeds between source potion and divination gates.
local categories = require("constants.catalog")
local ids = require("ids.xom_mod_events")

local definition = {
    id = ids.SECOND,
    name = "Second custom action",
    side = "good",
    effect_module = "policy.religion.xom.mod_effect",
    selector_module = "policy.religion.xom.mod_accept",
    selection_stage = 15,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
