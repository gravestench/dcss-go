-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_XOM_TRAIL,
    name = "magical condensation",
    color = "ETC_RANDOM",
    opaque = false,
    harmless = true,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.xom_trail",
}

register.definition(categories.CLOUDS, definition)

return definition
