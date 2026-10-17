-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_GLOOM,
    name = "gloom",
    verbose_name = "thick gloom",
    color = "MAGENTA",
    opaque = false,
    harmless = true,
    spread_rate = 50,
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.gloom",
}

register.definition(categories.CLOUDS, definition)

return definition
