-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_RAIN,
    name = "rain",
    verbose_name = "the rain",
    color = "ETC_MIST",
    opaque = false,
    harmless = false,
    spread_rate = 11,
    damage = {
        base = 0,
        random = 9,
        extra_player = false,
    },
    effect = "policy.clouds.effects.rain",
}

register.definition(categories.CLOUDS, definition)

return definition
