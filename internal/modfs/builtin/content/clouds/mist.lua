-- thin mist (ids.CLOUD_MIST) has spread rate 0 and is harmless to occupants.
-- Placement and aging use this record; exposure skips its occupant effect.

-- Source: crawl-ref/source/cloud.cc:clouds and cloud-type.h.
local categories = require("constants.catalog")
local ids = require("ids.clouds")

local definition = {
    id = ids.CLOUD_MIST,
    name = "thin mist",
    color = "ETC_MIST",
    opaque = false,
    harmless = true,
    spread_rate = 0,
    -- Zero damage, opacity, and spread are field data; harmless exposure skips contact.
    damage = {
        base = 0,
        random = 0,
        extra_player = false,
    },
    effect = "policy.clouds.effects.mist",
}

register.definition(categories.CLOUDS, definition)

return definition
