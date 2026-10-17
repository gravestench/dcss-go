-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_HOLY,
    name = "blessed fire",
    color = "ETC_HOLY",
    opaque = true,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 4,
        random = 12,
        extra_player = true,
    },
    effect = "policy.clouds.effects.holy",
}

register.definition(categories.CLOUDS, definition)

return definition
