-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_TLOC_ENERGY,
    name = "translocational energy",
    color = "MAGENTA",
    opaque = true,
    harmless = true,
    spread_rate = 0,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.tloc_energy",
}

register.definition(categories.CLOUDS, definition)

return definition
