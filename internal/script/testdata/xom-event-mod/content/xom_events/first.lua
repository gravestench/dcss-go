-- An earlier ID at the same stage rejects, allowing the next event.
local categories = require("constants.catalog")
local ids = require("ids.xom_mod_events")

local definition = {
    id = ids.FIRST,
    name = "First custom action",
    side = "good",
    effect_module = "policy.religion.xom.mod_effect",
    selector_module = "policy.religion.xom.mod_reject",
    selection_stage = 15,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
