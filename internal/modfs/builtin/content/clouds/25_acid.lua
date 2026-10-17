-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_ACID,
    name = "acidic fog",
    color = "YELLOW",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 8,
        random = 22,
        extra_player = true,
    },
    effect = "policy.clouds.effects.acid",
}

register.definition(categories.CLOUDS, definition)

return definition
