-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_SPECTRAL,
    name = "spectral mist",
    color = "ETC_ELECTRICITY",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 4,
        random = 15,
        extra_player = false,
    },
    effect = "policy.clouds.effects.spectral",
}

register.definition(categories.CLOUDS, definition)

return definition
