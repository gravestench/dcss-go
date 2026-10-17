-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_POISON,
    name = "poison gas",
    color = "LIGHTGREEN",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 10,
        extra_player = false,
    },
    effect = "policy.clouds.effects.poison",
}

register.definition(categories.CLOUDS, definition)

return definition
