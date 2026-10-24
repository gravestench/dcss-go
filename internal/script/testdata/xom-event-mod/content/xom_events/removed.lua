-- An intentionally retired mod event must never enter the action lottery.
local categories = require("constants.catalog")
local ids = require("ids.xom_mod_events")

local definition = {
    id = ids.REMOVED,
    name = "Retired custom action",
    side = "good",
    status = "removed",
    selection_stage = 12,
}

register.definition(categories.XOM_EVENTS, definition)

return definition
