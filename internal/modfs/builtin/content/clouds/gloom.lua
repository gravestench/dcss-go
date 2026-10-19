-- gloom (ids.CLOUD_GLOOM) has spread rate 50 and is harmless to occupants.
-- Placement and aging use this record; exposure skips its occupant effect.

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
    -- Zero damage, opacity, and spread are field data; harmless exposure skips contact.
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.gloom",
}

register.definition(categories.CLOUDS, definition)

return definition
