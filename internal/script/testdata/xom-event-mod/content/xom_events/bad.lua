-- A harmful mod action joins the source sequence after noise.
local categories = require("constants.catalog")
local ids = require("ids.xom_mod_events")

local definition = {
    id = ids.BAD,
    name = "Custom bad action",
    side = "bad",
    effect_module = "policy.religion.xom.mod_effect",
    selector_module = "policy.religion.xom.mod_accept",
    selection_stage = 25,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
