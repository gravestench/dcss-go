-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_NEGATIVE_ENERGY,
    name = "negative energy",
    color = "ETC_INCARNADINE",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 6,
        random = 16,
        extra_player = true,
    },
    effect = "policy.clouds.effects.negative_energy",
}

register.definition(categories.CLOUDS, definition)

return definition
