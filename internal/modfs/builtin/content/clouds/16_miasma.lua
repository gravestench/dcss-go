-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_MIASMA,
    name = "foul pestilence",
    verbose_name = "dark miasma",
    color = "DARKGREY",
    opaque = false,
    harmless = false,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 12,
        extra_player = false,
    },
    effect = "policy.clouds.effects.miasma",
}

register.definition(categories.CLOUDS, definition)

return definition
