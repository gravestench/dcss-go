-- Silver Haze is a harmless opaque cloud with its own Lua effect path.

local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_TEST_CUSTOM,
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
