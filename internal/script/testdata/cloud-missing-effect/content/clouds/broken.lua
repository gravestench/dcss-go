-- Broken Cloud is valid content whose missing effect module should fail coverage.

local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_TEST_BROKEN,
    name = "broken cloud",
    color = "WHITE",
    harmless = true,
    opaque = false,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.not_present",
}

register.definition(categories.CLOUDS, definition)

return definition
