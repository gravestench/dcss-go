local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_TEST_CUSTOM,
    source_order = 35,
    name = "silver haze",
    color = "LIGHTGREY",
    harmless = true,
    opaque = true,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.custom",
}

register.definition(categories.CLOUDS, definition)

return definition
