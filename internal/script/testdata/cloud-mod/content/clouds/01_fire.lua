local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_FIRE,
    source_order = 1,
    name = "violet flame",
    color = "MAGENTA",
    harmless = false,
    opaque = false,
    spread_rate = 0,
    damage = {
        base = 6,
        random = 16,
        extra_player = true,
    },
    effect = "policy.clouds.effects.fire",
}

register.definition(categories.CLOUDS, definition)

return definition
