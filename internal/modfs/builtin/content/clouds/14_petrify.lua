-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_PETRIFY,
    name = "calcifying dust",
    color = "WHITE",
    opaque = true,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.petrify",
}

register.definition(categories.CLOUDS, definition)

return definition
