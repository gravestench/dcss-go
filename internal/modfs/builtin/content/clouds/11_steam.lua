-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_STEAM,
    name = "steam",
    verbose_name = "a cloud of scalding steam",
    color = "LIGHTGREY",
    opaque = true,
    harmless = false,
    spread_rate = 22,
    damage = {
        base = 0,
        random = 16,
        extra_player = false,
    },
    effect = "policy.clouds.effects.steam",
}

register.definition(categories.CLOUDS, definition)

return definition
