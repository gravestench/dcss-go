-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_FLUFFY,
    name = "white fluffiness",
    color = "WHITE",
    opaque = true,
    harmless = true,
    spread_rate = 22,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.fluffy",
}

register.definition(categories.CLOUDS, definition)

return definition
